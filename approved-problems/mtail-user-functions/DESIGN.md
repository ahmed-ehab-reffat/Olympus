# DESIGN — mtail user-defined functions

## 1. Title

Add user-defined functions to the mtail program language.

## 2. Repo + base

- `google/mtail`, Apache-2.0, 4024 stars, Go, 26.9k LOC total (15.7k non-test).
- BASE `4c7e0e1174ac1ead032efe28d86428bbbe0ae145` (2026-02-26, tip of `main`).
- Pipeline architecture: lexer -> goyacc parser -> AST -> symbol table -> checker (Hindley-Milner
  unification) -> optimiser -> codegen -> stack bytecode VM -> metric store -> exporters.

### Gate evidence

| Gate | Result |
|---|---|
| 1 behavioural F2P gap | Base rejects `func`/`return`/call syntax outright; language reference states "User defined functions are not supported". |
| 2 saturation | mtail's language is its own; no external spec to port. |
| 3 uniform-wrap | 6 interdependent traps, two of which oppose each other (T1 vs T2). |
| 4 LOC ceiling | New machinery in 9 source files; VM has no call/frame/local concept at all. |
| 5 cold-not-live | Last commit 2026-02-26; every open PR is dependabot. Upstream dev has moved to the 29-star fork `jaqx0r/mtail`, which carries only dependency bumps. |
| 6 reproduce-on-base | `func f(x) { return x }` -> parse error on base. |
| 7 dedup | One prior submission on this repo (`mtail-foreach-match`, iteration over matches/metric entries) - a different capability. No function/call/frame work in the corpus for a log-processing VM. |
| 7b exclusivity | `gh pr list -R google/mtail --state all` = dependabot only; fork commits = dependency bumps only. No PR touches the compiler. |
| 8 defined-behaviour | Issue #333 (open) - maintainer jaqx0r: "There's no other concept of temporary variables, but there could be. I can leave this open as a feature request." Nothing declines functions. (#970 multi-line IS declined - avoided.) |
| 9 flakiness | Vanilla `go test ./...` in `olympus-base-go`: 21 packages ok, 0 fail, run 3x offline with identical results, ~7s. |
| 10 repo quota | 1 of 6 ours; 4024 stars is under the 5k presumed-global-saturation line. |

## 3. Shape

O-Composite-add: a new language construct threaded through every stage of an existing compiler and
VM. String-driven (mtail programs are runtime strings), so F2P is clean at the behavioural level.

## 4. Public API surface (program language, not Go)

```
func NAME(p1, p2) { ... return expr ... }     declaration
NAME(a, b)                                    call, in expression or statement position
return expr                                   returns from the enclosing function
```

No new exported Go symbols are required of the solver; every test drives the compiler and VM
through the existing `runtime`/`vm`/`compiler` entry points with program text.

## 5. Semantics (the contract)

1. `func` declares a function at the top level of a program. Its body is an ordinary statement list.
2. A call is an ordinary expression: it may appear anywhere a value may, and as a statement.
3. `return expr` leaves the function with that value. Reaching the end of the body without a
   `return` leaves the zero value of the function's result type (`0`, `0.0`, or the empty string).
4. Parameter and result types take part in the same inference as the rest of the program. A
   function has one type: the body and every call site unify into it (the declared type is unified
   directly, NOT freshened the way `types.Builtins` are), and the result flows on into the type of
   whatever the call feeds. Calling with the wrong number of arguments, or calling an undeclared
   name, is a compile error.
5. Parameters are storage local to the call. Assigning to one does not affect the caller. A
   parameter shadows a metric of the same name for the extent of the body.
6. **Capture groups inside a body belong to matches made inside that body, and a call leaves the
   caller's match state untouched** - the capture groups it can see, and whether an `otherwise` in
   the caller's scope fires.
7. **The timestamp register is shared**: `settime`/`strptime` inside a body change the program's
   timestamp and the change outlives the call.
8. A function may call itself. Nesting deeper than 100 calls is a runtime error for that line.
9. A body may declare storage of its own with `local NAME`, starting at the zero value of its type;
   `local` outside a function is a compile error. The program printer and the s-expression dump
   must render the new forms - both `panic` on an unknown node today, so `mfmt` and `--dump_ast`
   crash without them.
10. `stop` inside a body stops the program for the line. `next` outside a decorator is a compile
   error. A function must be declared before it is called, and may not be declared inside a block,
   a decorator, or another function.

## 6. Trap matrix

| # | Class | Mechanism | Misdirection |
|---|---|---|---|
| T1 | S1 speculative-state isolation (**lead**) | `thread.matches` is a map keyed by the *global* regex constant index and `thread.matched` is a single flag. The natural implementation runs the body on the caller's thread, so a match inside the callee clobbers the caller's capture groups and sets its matched flag. | Failure surfaces as a wrong metric value or an `otherwise` block that fires (or does not) - nothing points at the match register. |
| T2 | S2 composition, **opposes T1** | The obvious fix for T1 - snapshot and restore the thread around the call - also restores the timestamp register, so `strptime` inside a function silently stops working. Only a partial save is correct. | Surfaces as an export timestamp regression in an unrelated test. |
| T3 | S3 baseline preservation | Decorators are inlined by codegen through a `decos` stack that `next` unwinds. Implementing calls by AST inlining, or by pushing onto that stack, breaks existing decorator tests; touching `thread` naively breaks the vm and codegen golden tests. | Base-mode failures, far away from the feature. |
| T4 | S4 machinery-riding | A call must work as a builtin argument, as a metric index, on the right of `+=`, inside a decorated block, inside a conditional, nested in another call, and inside a function body. Stack discipline breaks first in nesting. | Wrong values, not crashes. |
| T5 | A12 type gate | One type per function, unified across the body and every call site. mtail's own builtin path calls `types.FreshType` first, which gives a fresh type per call site; copying that idiom passes every single-call-site test but decouples the body's inferred parameter type from the call. | Wrong metric type or a spurious conversion error, never a message about freshening. |
| T6 | architecture-jump block | Recursion, with a depth limit that raises a runtime error. Forbids the "inline the body like a decorator" shortcut that would defeat T1-T4 in one move. | - |

CONTRACT-STATED/FIX-HIDDEN holds for each: stating rules 6/7 does not say where the VM keeps match
state or how to split a frame save; stating rule 4 does not say to build a function type operator.

## 7. File footprint (measured)

438 human-effective LOC across 12 hand-written files (`code/object.go`, `code/opcodes.go`,
`ast/ast.go`, `ast/walk.go`, `symbol/symtab.go`, `checker/checker.go`, `codegen/codegen.go`,
`parser/lexer.go`, `parser/parser.y`, `parser/unparser.go`, `parser/sexp.go`, `vm/vm.go`).
`parser/parser.y` is the grammar source; `parser/parser.go` is regenerated by goyacc and is excluded
from the reviewer's meaningful count as a generated file (the LOC hook reports 837 including it).

## 8. Solution outline

- **code**: `Call`, `Ret`, `Lload`, `Lset` opcodes; `Object.Functions []FuncInfo{Name, Addr, Params, Locals}`.
- **ast**: `FuncDecl{Name, Params, Body, Scope, Symbol}`, `CallExpr{Name, Args, Symbol}`, `ReturnStmt{Expr}`.
- **types**: `Function(params..., result)` type operator plus arity-aware unification.
- **symbol**: `FuncSymbol`, `LocalSymbol` kinds; locals carry a frame slot in `Addr`.
- **checker**: declare the function symbol before walking its body (so recursion resolves), push a
  body scope holding the parameters, unify each call's arguments and result against the single
  function type, reject arity errors, undefined calls, nested declarations, `next` outside a
  decorator, and `return` outside a function.
- **codegen**: emit each body out of line behind a `Jmp`, record its entry address, allocate frame
  slots, emit a zero-value `return` epilogue, and emit `Call` at call sites after the arguments.
- **vm**: a frame stack holding return address, locals, and a *partial* snapshot (`matches`,
  `matched`) - deliberately not the timestamp; depth limit; `Ret` restores the snapshot and leaves
  the result on the data stack.

## 9. Test suite (97 nodes, all failing on base)

Declaration/parse, call in every expression position, statement calls, nesting, recursion +
depth-limit runtime error, parameter locality, shadowing, capture-group isolation both directions,
`otherwise` after a call, `matched` non-leak, timestamp persistence through a call, type unification
across call sites (int/float/string), metric type propagation, arity and undefined-call errors,
`return` outside a function, nested and duplicate declaration errors, unused declarations,
zero-value fall-off for each result type, decorator x function composition, `del`/`stop` inside a
body, `local` storage (zero initialisation, per-call independence, scope errors), and the two
program printers (stable unparse round trip, s-expression dump).

## 10. Tier

Olympus. Predicted pass rate 10-25%: the type unification and the frame plumbing are reachable, but
T1/T2 together (isolate matches, share time) plus T4 nesting are what the batch will fall on.

## 11. Quality gates

- [ ] human-effective LOC >= 450 (hook)
- [ ] every new test fails on base, passes with solution
- [ ] base suite green in both patch orders, 3x deterministic
- [ ] meta <= 500 words, ASCII, no enumerated wall list (Rule 7)
- [ ] no comments added to source (mtail's own new code carries few; match file convention)
