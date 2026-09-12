# Add user-defined functions to the mtail program language

mtail programs can only reuse code through decorators, and the language reference says user defined
functions are not supported.

A `func` declaration names a function, lists its parameters, and gives it a body of ordinary
statements, as in `func scale(n, factor) { return n * factor }`. Declarations live at the top level
of a program, and declaring one anywhere else is a compile error. A function has to be declared
before it is called. A call is written `scale($1, 3)`. It is an ordinary expression, so it may
appear anywhere a value may, and on its own as a statement, and one that yields a boolean works as
a condition. `return` takes an expression and leaves the function with its value, and a body that
finishes without returning leaves the zero value of its result type: 0, 0.0, false or the empty
string. A function may call itself, and a program with more than a hundred calls active at once
raises a runtime error that stops the program for the line being processed.

A function has one type: its parameters and its result are inferred from the body and from every
call together, so every return leaves a value of the one result type and every call site agrees on
the parameter types, and the result flows on into the type of whatever the call feeds. Types that
differ combine as they already do elsewhere in the language. Calling a name that is not a function,
or passing the wrong number of arguments, is a compile error.

A parameter is storage local to the call. Assigning to one changes nothing for the caller. A body
may declare storage of its own with `local`, which starts at the zero value of its type, and a
parameter or a local shadows a metric of the same name wherever it is in scope. A function's name
has to be distinct from every other name declared at the top level. Declaring the same function or
local twice, reusing a parameter's name for a local, repeating a parameter name, using `return` or
`local` outside a function, and leaving a declaration unused are all compile errors.

Capture groups inside a body belong to the matches made inside that body, and a call leaves its
caller's match state alone: the caller keeps the capture groups it had, and whether an otherwise
block in the caller's scope runs is decided only by the caller's own matches. The timestamp
register is not part of that. It belongs to the program, so a body that parses or sets a time
changes the timestamp of the metrics its caller writes afterwards.

Patterns, conditionals, otherwise blocks, metric reads and updates, `del` and `stop` behave inside
a body exactly as they do outside, a call works inside a decorated block, and the tools that print
a program back out render the new forms, parameters and call arguments included.
