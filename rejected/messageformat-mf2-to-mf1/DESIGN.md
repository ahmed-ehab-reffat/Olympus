# DESIGN.md — messageformat-mf2-to-mf1

Repo: messageformat/messageformat (TypeScript monorepo, MIT root / Apache-2.0 mf2 packages, 1770 stars)
Base: 0ffba11d49b1aa4579497ccec7fb9ec3c082e709 (main HEAD, 2026-04-26; origin/main has nothing newer)
Hunt: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-19-D.md` RANK 1. Picker check confirmed by user 2026-09-19.

## Phase 1 — Repo understanding

- **Architecture.** Two generations of one i18n library in one npm workspace. `mf1/` holds the ICU
  MessageFormat 1 stack: a moo-based parser (`@messageformat/parser`), a compiler to JS
  (`@messageformat/core`) and its runtime. `mf2/` holds Unicode MessageFormat 2: the data model,
  CST parser, resolver and formatter (`messageformat`), plus converters between MF2 and other
  syntaxes (`@messageformat/fluent` both ways, `@messageformat/icu-messageformat-1` MF1 -> MF2 only,
  `@messageformat/xliff`, `@messageformat/resource`).
- **Subsystems.** (1) MF1 parser/lexer (escape rules, `#`, case keys). (2) MF1 compiler + runtime
  (make-plural categories, strict plural keys). (3) MF2 data model + parser + resolver + `selectPattern`.
  (4) MF2 function registry (`:number`, `:integer`, `:string`, `MF1Functions` incl. `mf1:plural` with
  offset). (5) Converters (`mf1ToMessageData` lifting nested MF1 selects into one MF2 select table;
  `messageToFluent` lowering MF2 selects into nested Fluent selects).
- **Entanglement zones.** `mf2/messageformat/src/select-pattern.ts` (every select message);
  `mf2/icu-messageformat-1/src/mf1-to-message-data.ts` (argType/argStyle attribute encoding, offset,
  `#`); `mf1/packages/parser/src/{lexer,parser}.ts` (quoting and `#` context rules).
- **Tests.** vitest 4, colocated `src/*.test.ts`, run from the root (`npx vitest run`), tsconfig path
  aliases resolve workspace packages to source. Base: 36 files / 2709 tests, 3x identical.
- **Template test file.** `mf2/icu-messageformat-1/src/mf1.test.ts` (table-driven `describe`/`test`).

## Phase 2 — Exclusivity (run 2026-09-19, canonical `messageformat/messageformat`)

PR + issue search, all states: "MF1 serialize", "stringify MF1", "to MF1", "messageToMF1", "export
ICU", "convert to MessageFormat 1", "downgrade", "mf2 to mf1", "sparse variants", "fluent default
variant", "selectPattern", "infinite loop select", "select hang" -> only unrelated merged refactors
(#447 diff checked: forward direction only). `git log --all -S` for messageToMF1 / toMF1 /
stringifyMF1: empty. Changelogs: no removed MF1 serializer. origin/main == base.
GitHub code search: `worldware-studios/msg-cli` (0 stars, created 2025-12) `src/lib/pgs-mf1.ts`
serializes XLIFF PGS cases to nested MF1 by NAIVE grouping (`insertCase`), no sparse selection, no
locale categories, `#` for any plural var. Recorded as a scope-gate risk for the emitter half only;
the core (selection-faithful compilation of a sparse table) is absent there. The core-slice precheck
(Step 4b) is the arbiter.

## 1. Title
Add MessageFormat 2 to ICU MessageFormat 1 conversion

## 2. Shape
O-Algorithm-correctness (new variant of an existing converter family, subtle selection semantics)
plus an O-Composite second package (runtime selection fix). Dominant verdict predicted:
WRONG_LOGIC / MISSED_REQUIREMENT on composition cells.

## 3. Public API
- `messageToMF1(locale: string, msg: Model.Message): string` — exported from
  `@messageformat/icu-messageformat-1`; a plain function, two positional parameters, returns MF1 source.
- `MessageFormat#format` / `formatToParts` — selection must terminate and pick the spec variant.
- Errors: `messageToMF1` throws (any `Error`) for unconvertible input. Tests use bare `toThrow()`.

## 4. Canonical output form
Not pinned. Every conversion test is behavioural: `mf1ToMessage(locale, src)` formats a value grid
identically to the MF2 original (both `bidiIsolation: 'none'`), plus a validity check that parses
`src` with `@messageformat/parser` given the locale's `Intl.PluralRules` categories
(`strictPluralKeys` on) and checks every plural/selectordinal statement has an `other` case.

## 5. Blind-spot pre-empts
- Sparse variant lists stated explicitly (the headline) — contract, not fix.
- Result ordering / dedup: n/a. Iteration termination: runtime fix sentence.
- ≤1 codebase-inferable requirement: MF1 quoting rules (lexer).

## 6. Description draft
See `meta.md` (drafted together with this file; ~260 words).

## 7. File footprint (reference)
| Action | Path | Raw | Eff (est) |
|---|---|---|---|
| NEW | mf2/icu-messageformat-1/src/message-to-mf1.ts | ~330 | ~250 |
| MODIFY | mf2/icu-messageformat-1/src/index.ts | +1 | 1 |
| MODIFY | mf2/messageformat/src/select-pattern.ts | ~+30/-20 | ~25 |
| MODIFY | mf2/icu-messageformat-1/README.md | +docs | 0 |
Target >= 280 human-effective. Leanest plausible passer (representative-value probing through the
runtime) estimated ~200-230; recheck against saved passers after batch 1.

## 8. Solution outline (helpers)
- `resolveDecl(ctx, name)` — follow `.local`/`.input` to the bound expression + input variable.
- `selectorInfo(ctx, ref)` — classify a selector: plural | selectordinal | select, offset, exact-only.
- `branches(sel, keys, locale)` — MF1 cases of one selector, each with its ordered preference list:
  `=n` -> [n, category(n - offset)], category c -> [c], other -> [], restricted to keys present;
  categories from `Intl.PluralRules(locale, {type}).resolvedOptions().pluralCategories`.
- `bestVariant(variants, prefs)` — lexicographic spec selection over the leaf's preference lists.
- `buildTree(depth, prefs)` — recursive nesting; collapse cases equal to `other`.
- `patternToMF1(pattern, ctx, pluralStack)` — text escaping (run-quoting, `#` only inside plural
  context, apostrophe doubling) and placeholders (`#` only when the innermost plural is the same
  variable with the same offset, otherwise an inline `{n, plural, offset:k other {#}}` wrapper).
- `expressionToMF1(expr)` — attribute write-back, `:number`/`:integer`/`:string`, literals.
- `selectPattern` — proper backtracking to the nearest earlier selector still holding a key.

## 9. Tests (one new file `mf2/icu-messageformat-1/src/message-to-mf1-<hex>.test.ts` + a runtime
test in `mf2/messageformat/src/select-<hex>.test.ts`)
Helpers: `check(locale, src, grid)` builds both formatters and compares every grid point;
`valid(locale, mf1)` strict-parses and checks `other`. Buckets: pattern messages; placeholders +
declarations; escaping; single selector (plural, ordinal, exact, string); sparse 2-selector tables;
offset; locale categories (en, pl, ru, ar, cy); 3-selector tables; MF1 round trip of existing syntax
(argType/argStyle); errors; runtime termination; seeded generated corpus (fixed PRNG, 2-3 selectors,
all locales, values 0..30 + 100..111 + 1000).

## 10. Forced shapes
Named function export, positional `(locale, msg)` mirroring `mf1ToMessage(locales, source)`; stated
in meta (L72).

## 11. Trap matrix
| # | Trap | F-id | Class | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| 1 | Sparse table nested naively (group by first key, as `messageToFluent` does): a leaf misses the variant MF2 reaches by backtracking | F-1 / F-11 (in-repo misdirecting precedent) | S2 | selection semantics | 2, 3, 6 | 2-selector sparse cells |
| 2 | Exact case `=n` falls back to the category of `n` WITHOUT the offset, or with cardinal rules for an ordinal | F-10 cell (offset x sparse, ordinal x sparse) | S2 | preference list per case | 1 | offset/ordinal sparse cells |
| 3 | Literal `other` key vs `*`: MF1 `other` also catches categories without a case; locales with >2 categories need explicit cases, and those must be categories the locale has (strict keys) | F-18-like (two spellings of the fallback) + F-10 locale cell | S2 | locale category set | 1 | pl/ru/ar/cy cells, strict parse |
| 4 | `#` is the INNERMOST plural's value; offset placeholders need `#`, and a nested plural over another variable steals it; outside plural context there is no `#` | F-7 (nested context) | A8 | placeholder scope | 1 (tree order decides nesting) | offset x nested-plural cells |
| 5 | Quoting: adjacent specials (`{}`) under per-character quoting misparse; `#` must be quoted only inside plural context, and `'#...'` outside plural is kept literally or throws | F-7 / P3 self-test shadow | A9 | text escaping | 4 (same context stack) | escaping cells |
| 6 | Runtime `selectPattern` loops forever when the backtracked selector already sits on its catch-all; oracle-probing converters inherit it | S3 baseline + S5 dual-path | S3 | termination | 1 | 3-selector runtime + conversion cells |
| 7 | Declarations followed to their bound expression (`.local` chains, `.input` annotation on a bare placeholder) | S4 | A-tier | expression resolution | 4 | declaration cells |

Axes are distinct; 1 is interdependent with 2, 3 and 6 (all compute the leaf's preference list);
4 and 5 share the plural-context stack.

### 11b. Cross-product
| | 1 selector | 2 selectors sparse | 3 selectors sparse |
|---|---|---|---|
| no offset, cardinal | base | T1 | T1+T6 |
| offset | T2/T4 | T2 x T1 | T2 x T6 |
| ordinal | T2 | T2 x T1 | |
| literal other, pl | T3 | T3 x T1 | |
| `#`/escape in leaf | T4/T5 | T4 x T1 (leaf under another plural) | |

Scope audit: "every non-negative integer" for numeric variables, strings otherwise. No iteration or
size promise (L44/L45).

## 12. Tier / category
Olympus. Category feature-request (Add ...).

## 13. Predicted pass rate
15-30%. The kernel insight is one idea, but five orthogonal detail axes each carry an independent
miss probability and the seeded corpus crosses them.

## 14. Quality gate
- [x] Phase 1 5/5 - [x] Phase 2 clean (msg-cli risk logged) - [x] shape - [x] API named with call shape
- [x] behavioural tests only, no source pins - [x] traps on distinct axes, interdependence present
- [x] 11b filled - [x] no unbounded promise - [x] no exact-float asserts (integers only)
- [ ] core-slice precheck (Step 4b) — owed before differentiating scope

## Why this is not a duplicate
No approved problem converts MF2 to MF1. Closest: babel-icu-messageformat (sibling workspace,
Python MF1 formatting, different repo and direction) and featurevisor (TS, unrelated domain).

Predicted iteration cycles: 2.
