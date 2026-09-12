# Implement WebAssembly exception handling in the tinywasm runtime

The runtime does not support WebAssembly exception handling. Extend it so that it executes modules which define, import, and export exception tags and use `throw`, `try_table`, `throw_ref`, and `exnref`, as well as the legacy `try`, `catch`, `catch_all`, `delegate`, and `rethrow` forms.

`throw` removes the tag's parameter values from the stack, packages them into an exception, and transfers control to the nearest enclosing handler that matches. Tags match only when they are the same definition. Imported and exported tags appear among the module's imports and exports.

A `try_table` block lists catch clauses that are tried in written order, the first match winning. A `catch` pushes the exception's parameter values and branches to its label; a `catch_ref` pushes those values and then an `exnref` referring to the exception; `catch_all` and `catch_all_ref` match any tag, pushing nothing or an `exnref`. Before the caught values are pushed, the value stack is returned to its height at block entry. `throw_ref` re-throws the exception referred to by an `exnref`, keeping its original tag and values, and traps on a null reference.

The legacy `catch` and `catch_all` clauses match as in a `try_table` and run an inline body. `delegate` forwards a thrown exception to the handler enclosing the target named by a label depth, or to the caller when it names the function body. `rethrow`, valid inside a catch body, re-raises the exception caught by the `try` at a given label depth.

If no handler matches, the search continues outward and across called functions, discarding the call frames in between. Leaving a handler region removes its handlers. An exception that escapes the top-level call is uncaught and fails the invocation as a trap.
