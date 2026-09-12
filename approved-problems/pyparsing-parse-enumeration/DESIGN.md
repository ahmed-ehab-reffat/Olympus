# DESIGN — pyparsing: enumerate every parse of an ambiguous grammar

## 1. Title

Enumerate all parses of an expression (ambiguity enumeration) in `pyparsing`.

Repo: <https://github.com/pyparsing/pyparsing> · Language: Python · License: MIT · 2.5k stars ·
pushed 2026-07-19 (active) · base commit `d3388aaf5c60d1069b7294a743ccd0e7c87a1d1d`.

## 2. Shape classification

O-Pipeline-hard / new load-bearing engine capability. A second evaluation mode is added *alongside* the
existing single-result parse path, and every expression class must participate in it. Not a wrapper over
existing API: pyparsing returns exactly one parse per start location and has no machinery that yields
alternatives.

## 3. Pick-gate record

| Gate | Verdict |
|---|---|
| 1 BEHAVIORAL-F2P-GAP | PASS. No enumeration API exists (`grep all_matches/ambigu/enumerate` in `core.py` → only `list_all_matches` results-name flag). Not composable: `scan_string` yields one parse per *start location*, never two parses at the same location. New API absent on base → F2P clean. |
| 2 SATURATION | PASS. Not a port of a known reference; there is no canonical "pyparsing all-parses" implementation to recall. Enumeration order + action semantics are defined by *this* engine's preference rules. |
| 3 UNIFORM-WRAP | PASS. No single mechanism discharges the walls: ordering rules differ per class, laziness/action-once is orthogonal to ordering, packrat equivalence is orthogonal to both, and `parse_all` filtering defeats any "wrap `parse_string`" architecture. |
| 4 LOC-CEILING | MEASURED: human-effective 408, raw 601, Counter-1 481, 3 files — clears the 250 sprint floor and the 400 auto-block. Breadth is irreducible: each composite class carries its own enumeration logic (sequence product, ordered union, longest-first union, greedy repetition, optional, lookahead existence, wrapper fidelity, recursion cut, permutation) plus the per-parse finalize path and the three public drivers. |
| 5 COLD-NOT-LIVE | PASS. No commit, PR, or issue touching ambiguity enumeration; `core.py` churn is unrelated (deprecations, `as_datetime` fix). |
| 6 REPRODUCE-ON-BASE | N/A (new capability). Trap reproduction is done instead (§10): the natural-but-wrong implementation is written and confirmed failing. |
| 7 DEDUP | PASS. No parser-enumeration submission in `problems/`, `rejected/`, `Aprroved/`. Nearest neighbours are different classes: `ohm-cut-operator` (backtracking control), `lark-operator-precedence` (precedence), `peggy-left-recursion` (recursion). |
| 7b EXCLUSIVITY | PASS. `gh pr list -R pyparsing/pyparsing --state all --search "ambiguous OR ambiguity OR all_parses OR enumerate"` → no hits. Canonical org confirmed `pyparsing/pyparsing`. |
| 8 DEFINED-BEHAVIOR | Invented capability, so the contract is defined in `meta.md` in full; every rule is derived from ONE principle (the engine's own preference order), not a spec sheet. No maintainer decline; `CONTRIBUTING.md` invites feature issues, no maintenance freeze. |
| 9 NO-FLAKY-REPO | PASS. `pytest tests/` 3x: `2025 passed, 27 skipped, 2029 subtests passed` identical every run (45-60s). |
| 10 REPO-QUOTA | PASS. 0 prior submissions in our dirs; 2.5k stars (under the 5k presumed-global-saturation line). |

## 4. Public API surface

Three generator methods on `ParserElement` (all documented verbatim in `meta.md`) plus one exported
type alias:

- `enumerate_parses(instring, *, parse_all=False, max_parses=None, unique=False)` — yields
  `(tokens, start, end)` triples, mirroring `scan_string`'s yield shape.
- `enumerate_scan(instring, *, max_parses=None, overlap=False, unique=False)` — the same enumeration at
  every start location, mirroring `scan_string`'s scanning/`overlap` behaviour.
- `enumerate_transforms(instring, *, max_parses=None)` — every distinct string `transform_string` could
  produce, each once.
- `EnumeratedParse` — the yielded triple's type alias.

No new public class, no config object, no typed callback. Python, so no compile coupling: a wrong
signature guess cannot zero out the whole suite the way a Rust/Go API mismatch does.

## 5. The contract (canonical form)

ONE principle, from which every per-class rule follows: **parses are enumerated most-preferred first,
where "preferred" is the order the ordinary parser would try them.** Consequences (stated in the meta as
prose, never as a per-class table):

1. sequence (`+`): the last element's parses vary fastest;
2. `|` (`MatchFirst`): every parse of the first alternative before any of the second;
3. `^` (`Or`): by decreasing end location; ties in operand order;
4. `ZeroOrMore`/`OneOrMore`/`DelimitedList`: greedy — more repetitions before fewer; a repetition that
   consumes nothing ends the repetition; the zero-repetition parse comes last;
5. `Opt`: present before absent (absent yields the default when one was given);
6. lookahead (`FollowedBy`, `NotAny`, and the positional assertions): one zero-width parse when the
   condition holds; `NotAny` holds when the contained expression has no parse;
7. wrappers (`Group`, `Suppress`, `Combine`, results names, `Forward`): one parse per contained parse,
   transformed exactly as ordinary parsing transforms it (so `Combine` still rejects non-adjacent parses);
8. `Each` (`&`) yields the orderings of its operands that match, in increasing lexicographic order of
   matched operand index, or the single ordinary parse when an operand is optional or repeated;
9. `SkipTo` yields one parse per position its target matches, nearest first;
10. terminals, and any class not listed, yield the parse ordinary parsing produces.

Cross-cutting rules:

- **Action-once + pruning:** for every parse yielded, that expression's parse actions and conditions run
  exactly once, in order; a condition/action raising `ParseException` discards that parse only and
  enumeration continues; `ParseFatalException` propagates.
- **Laziness:** parses are produced on demand; no actions run for parses that are never yielded (`Or` must
  examine its alternatives in order to order them by length).
- **`parse_all=True` filters** to parses reaching the end of the input, so a whole-string parse is yielded
  even when the greedy parse that `parse_string` returns stops early.
- **First parse agrees with `parse_string`** when `parse_all=False`.
- **Packrat-independent:** the enumerated parses are the same with and without `enable_packrat()`, and
  ordinary `parse_string` behaviour is unchanged.
- **No parses → yields nothing** (never raises `ParseException`).
- **Termination:** a `Forward` is not re-entered at a location where it is already being matched, so a
  left-recursive grammar enumerates its non-recursive parses instead of recursing forever.
- **`unique`:** skips a parse whose tokens, names and end location repeat one already yielded.

## 6. Trap matrix (CONTRACT-STATED / FIX-HIDDEN checked per row)

| # | Arsenal class | Mechanism | Misdirection | Fix hidden? |
|---|---|---|---|---|
| W1 | S3 baseline preservation through the shared chokepoint | enumeration has to route through `preParse`/`postParse`/results-name/action logic that `_parseNoCache` owns; the tempting move is to generalise `_parse`/`parseImpl` signatures or the packrat cache | failures land in the 2025-test baseline (`Or` re-evaluation, packrat, `IndentedBlock`), not in the new tests | YES — contract says "existing behaviour unchanged"; the fix (mirror the finalize path instead of refactoring it) is a framework-internals discovery |
| W2 | S1 / P2 over-eagerness | actions must fire once per *yielded* parse; buffering all parses first (the natural generator-free impl) fires actions for parses nobody consumed | assertion is a side-effect counter, far from any parse result | YES — stating "lazy, once per yielded parse" does not say where to put the generator boundary |
| W3 | S2 composition of documented rules | the four ordering rules interact: greedy repetition nested inside a sequence inside `^`; exactly one total order is correct, and ≥2 tempting exits (rightmost-slowest nesting, fewest-repetitions-first) each break a different test | wrong order looks like a missing/extra parse in the middle of a list | YES — each rule is documented; their product is not transcribable |
| W4 | architecture-forcing | `parse_all=True` must find parses the greedy first parse misses; any "call `parse_string` and perturb" architecture cannot | test shows a missing parse for a grammar that `parse_string(parse_all=True)` rejects | YES |
| W5 | A9 exact-fit shape | zero-length repetition bodies must terminate the repetition; agents self-test on non-empty bodies | a hang / RecursionError, not a wrong value | YES |
| W6 | S2 + interdependence with W2 | an action raising `ParseException` prunes one parse; impls that pre-buffer either abort enumeration or leak the pruned parse | wrong parse count with a correct-looking order | YES |
| W7 | S4 machinery-riding | every wrapper/converter must transform each parse (Group nesting, Suppress, Combine adjacency, results names, `Forward` recursion) | tokens subtly wrong deep in a nested structure | YES |
| W8 | S6-flavoured second evaluator | `NotAny` must ask "does any parse exist" with actions off; `FollowedBy` keeps named results only | a negative lookahead silently admits a parse | YES |

Interdependence: W2×W6 (laziness vs pruning pull in opposite directions), W1×W3 (the refactor that makes
ordering easy is the one that breaks the baseline), W4×W3 (the architecture that gets ordering cheaply
cannot satisfy `parse_all`).

## 7. File footprint (planned)

| File | Change |
|---|---|
| `pyparsing/core.py` | `ParserElement._enumerate` (per-parse finalize path), `_enumerate_impl` default, overrides on `And`, `Or`, `MatchFirst`, `_MultipleMatch`, `Opt`, `ParseElementEnhance`, `FollowedBy`, `NotAny`, public `enumerate_parses` / `enumerate_scan` |
| `pyparsing/enumeration.py` (new) | driver: tab expansion, streamlining, `parse_all` end check, `max_parses`, start-position scanning with `overlap`, packrat-safe reset |
| `pyparsing/__init__.py` | module wiring / export list |

## 8. Test outline (F2P)

Blocks: (a) ordering per rule and in composition; (b) action-once + laziness counters; (c) action/condition
pruning; (d) `parse_all` filtering incl. the parse `parse_string` misses; (e) first-parse-equals-`parse_string`;
(f) wrappers (Group/Suppress/Combine/results names/Forward recursion); (g) lookahead existence semantics;
(h) zero-length repetition termination; (i) packrat on/off equivalence; (j) `enumerate_scan` + `overlap`;
(k) empty result (no parses) and `max_parses`.

Every assertion pins ordered token lists (`as_list()`) plus `start`/`end`, never a message substring.

## 9. Difficulty prediction

Long-horizon: ~500-700 LOC across 3 files, sequential (finalize path → per-class overrides → driver),
wide blast radius (a wrong finalize path fails every block), cross-cutting invariant (order + action
semantics + baseline). Predicted pass rate 10-30%; solvable because each class's rule is stated and the
work, while large, is mechanical once the architecture is right.

## 10. Verification plan

1. Reference implementation; full baseline green (2025 tests) 3x.
2. Trap reproduction: write the natural-but-wrong impl (buffer-all + `parse_string`-wrapping + first-parse
   lookahead) and confirm each discriminator fails.
3. F2P: every new test fails on base (API absent) and passes with the solution.
4. Flakiness 3x on both modes.
5. Docker offline non-root, both apply orders.
6. LOC measure with the hook; FP check last.


## 11. Build record (filled in after implementation)

- Solution: `pyparsing/core.py` (per-parse finalize path + `_enumerate` protocol + overrides on And, Or,
  MatchFirst, `_MultipleMatch`, Opt, Each, FollowedBy, NotAny, SkipTo, Forward, TokenConverter,
  DelimitedList + three public methods), `pyparsing/enumeration.py` (drivers: parses / scan / transforms,
  parse_all end check, structural dedup), `pyparsing/__init__.py` (`EnumeratedParse` export).
- Tests: `tests/test_parse_enumeration_f3843a.py`, 78 tests in 9 classes; `test.sh` with base/new modes,
  `--output_path` JUnit XML and an empty-XML fallback.
- Validation: 4-cell + reverse-apply green in Docker offline non-root; flakiness 3x identical;
  12-mutation trap proof all caught; FP check run both directions (two meta gaps fixed, one
  over-prescriptive test removed).
- Remaining: local imitator probe + the 10-run platform batch (the only difficulty oracle).
