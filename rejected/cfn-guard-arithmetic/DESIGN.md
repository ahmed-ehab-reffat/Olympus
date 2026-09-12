# DESIGN — cloudformation-guard: arithmetic expression sublanguage (issue #584)

## 1. Title
Add arithmetic operators to the Guard DSL expression language

## 2. Tier / shape / category
- **Tier:** Olympus (target ≥250 eff LOC, ≤40% pass).
- **Shape:** O-Composite-add / D-new cross-module variant — a new expression kind threaded through nom parser → AST enum (exhaustive-match sites) → evaluator → value model.
- **Category:** feature-request (net-new language capability).

## 3. The gap (issue #584, maintainer-accepted, cold, no PR)
Guard is a declarative assertion DSL with only comparison operators (`==`,`!=`,`<`,`>`,…) that return booleans. There is NO arithmetic: `let x = a + b`, `count(...) / total > 0.9`, etc. fail to parse. #584 asks for basic math in `let` bindings and assertion right-hand-sides; maintainer replied positively; no implementation exists. Base behavior: any arithmetic expression is a parse error (clean runtime-string f2p).

## 4. Scope of the feature (behavioral contract for meta.md)
Support binary arithmetic `+ - * / %` with standard precedence (`* / %` bind tighter than `+ -`), left-associativity, and `( )` grouping, plus unary minus. Arithmetic expressions are usable anywhere a `LetValue` is: `let` assignments, the right operand of a comparison clause, and function-call arguments. Operands may be numeric literals, variable/query references that resolve to a single numeric scalar, function-call results, or nested arithmetic. Semantics:
- Int op Int → Int (except `/` which yields Float when not evenly divisible — DECIDE + document one rule); Float involved → Float.
- `/` or `%` by zero → evaluation error (documented message substring).
- Operand resolving to a non-numeric or to a non-single value (a list/multiple query matches) → evaluation error.
- `%` defined for integers (and floats via truncated/`rem`, documented).

## 5. Why it does NOT compress (non-reuse machinery)
Guard's parser has no expression-precedence grammar (clauses are query-vs-literal comparisons). Arithmetic forces: (a) a new nom precedence parser (term/factor/primary levels), (b) a new recursive AST variant `LetValue::BinaryOperation { op, lhs, rhs }` + unary, (c) numeric evaluation over `PathAwareValue` with coercion/error rules, (d) threading the new variant through EVERY exhaustive match on `LetValue` (parser build, evaluator resolve, reporters, Hash/Serialize) — a cross-module REGRESSION surface. None reuses comparison-operator code.

## 6. File footprint (target ~300-400 eff LOC)
| File | role |
|---|---|
| guard/src/rules/exprs.rs | new `BinaryOperation`/`UnaryOperation` AST + `ArithOp` enum; thread into LetValue |
| guard/src/rules/parser.rs | precedence grammar: arith_expr → term → factor → primary(paren/literal/query/call) |
| guard/src/rules/evaluate.rs (+ eval/operators.rs) | resolve operands, numeric apply, coercion, errors |
| guard/src/rules/path_value.rs | numeric extraction/promotion helpers on PathAwareValue |
| other LetValue match sites | exhaustive-match updates (reporters, hash) |

## 7. HARDENED trap design (HARDENING.md — difficulty lives in DOING, CONTRACT-STATED/FIX-HIDDEN)

Plain arithmetic is a uniform-wrap (semantics trainable → too easy). Fair difficulty is loaded into integration/preservation. Confirmed collisions in the base grammar (parser.rs): `*` = query wildcard `QueryPart::AllValues` (:747,:766); `/` = regex delimiter `/re/` (:285).

- **LEAD S3 — baseline preservation through the shared parse chokepoint (the killer).** `*` (multiply) collides with the `.*` query wildcard; `/` (divide) collides with `/regex/`. The naive arithmetic grammar spliced into `let_value` BREAKS existing wildcard queries and regex clauses. Contract stated ("support `*` and `/`; all existing query and regex syntax keeps working; validate against the full base suite"); fix hidden (parse query/regex primaries greedily, admit an arith op only between resolved primaries — a parser-internals discovery). Misdirects: the failing test is an EXISTING query/regex test, not an arithmetic test. Base mode MUST run the existing parser/query/regex integration tests (shared path). REWIRE-THE-EXISTING-API: keep a public test that `Resources.*.X` and `X == /re/` still parse+evaluate.
- **S4 — machinery-riding operand resolution.** An arithmetic operand may be a query that resolves to 0 or many values (Guard queries are multi-valued). Contract: an operand must resolve to exactly ONE numeric scalar or it is an evaluation error (shares the resolve path with the existing single-scalar comparison semantics — regress-one-fix-another). One general sentence, tested across literal / single-query / multi-query / empty-query / non-numeric operands.
- **S2 — cross-operator precedence composition.** Arithmetic binds tighter than comparison (`a + b == c` ≡ `(a+b) == c`) and `* / %` tighter than `+ -`, left-assoc, parens override. Naive flat parse gives wrong values; each wrong exit fails a different discriminator.
- **A11 grammar wall + B support:** nom precedence levels resist transcription; Int/Float promotion, div/mod-by-zero as EVAL errors (natural kind), unary minus vs subtraction.

## 8. FP coverage matrix (both directions — mechanical clean by construction)
Every meta sentence → ≥1 discriminator test; every test → a meta sentence. Per-requirement discriminators: precedence (`2+3*4==14` AND `not 20`), assoc (`8-3-2==3`), paren override, `*`-not-wildcard-regression (existing `Resources.*` test in base mode), `/`-not-regex-regression, multi-value-operand error, empty-operand error, non-numeric error, div-by-zero error, mod semantics, int/float promotion, arith-tighter-than-comparison. No error-message substring pins (assert error occurs / status), no enumerated fix in meta (Rule-7: one sentence per family).

## 8. Reproduce-on-base (to confirm before build-measure)
`echo '{}' | cfn-guard ... rule with `let x = 1 + 2`` → parse error on base; passes on solution.

## 8b. Implementation status + exact remaining eval wiring (turnkey)

DONE + self-consistent: `exprs.rs` (`ArithmeticOperator` enum + `LetValue::BinaryOperation` + Display) and `parser.rs` (`let_primary`/`arithmetic_term`/`let_value` precedence grammar with `*`//`/` disambiguation by construction — a lone primary with no following operator parses exactly as before). `fold_many0` imported. These two files are complete.

REMAINING (the S4 evaluator integration) — 7 exhaustive-match arms + one shared numeric helper:

- **Shared helper** `resolve_arithmetic(op, lhs, rhs, resolver) -> Result<PathAwareValue>`: resolve each operand `&LetValue` to exactly ONE numeric `PathAwareValue::Int/Float` (Value→extract; AccessClause→`query_retrieval` then require single Resolved numeric else eval-error [S4]; FunctionCall→`resolve_function` single numeric; BinaryOperation→recurse). Apply op: Int⊕Int→Int (Divide→Float when not exact — PIN in meta), any Float→Float, `%` via rem, div/mod-by-zero→eval-error. No panics.
- **Site `eval_context.rs:102`** (`extract_variables`, NO resolver): add a 4th scope field `arithmetic: HashMap<&str,&LetValue>`; store BinaryOperation there.
- **Site `resolve_variable` (`eval_context.rs:~1117`)**: after functions branch, if name in `arithmetic` map → `resolve_arithmetic` → return `vec![QueryResult::Literal(Rc::new(v))]`, cache it. (let-assignment path)
- **Sites `eval.rs:1097,1591`, `eval_context.rs:833,2446`, `evaluate.rs:746,1052`** (compare_with / filter / param RHS, all HAVE a resolver): add `LetValue::BinaryOperation{..}` arm → `resolve_arithmetic` → produce the same value shape the sibling `LetValue::Value` arm produces at that site.

Verify order: build → `let x = 2 + 3 * 4` ⇒ 14 (precedence) → `Resources.*.X >= n` and `X == /re/` still parse (S3 preservation) → base suite green → then FP-safe tests.

## 9. Risks
- Where exactly arithmetic is allowed (design decision — keep to LetValue sites to bound scope).
- The `/` int semantics must be pinned in meta.md (ambiguity = FP-check failure).
- Exhaustive-match threading must not regress existing clause tests (run base suite each iter).
