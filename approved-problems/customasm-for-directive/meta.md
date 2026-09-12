# Add a `#for` compile-time repetition directive to the assembler

Add a `#for` directive that expands a block of source once for each value in an integer range. The syntax is `#for NAME in START, END { ... }`. The range is half open: NAME takes each value beginning at START, while END itself is excluded.

An optional third expression sets the step. A positive step counts up while NAME stays below END; a negative step counts down while NAME stays above END. A step of zero is an error, and an omitted step is one. A loop that runs zero times emits nothing and evaluates nothing in its body, though the body is still parsed and must be syntactically valid.

Inside the body, NAME may appear in any expression, where it shadows any symbol of the same name within the body. Each iteration is an independent scope for local symbols, that is labels or constants beginning with a dot: such a symbol may be declared and referenced within one iteration without colliding across iterations, while a non-local label or constant declared in the body collides when the loop runs more than once.

START, END, and the step may reference constants and the addresses of top-level labels, and may use constants defined later in the file; they are resolved through the assembler's normal address resolution. A range that never resolves to integer values is an error.
