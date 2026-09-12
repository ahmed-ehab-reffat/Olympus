# Add aggregate expressions over iterables to rule conditions

A condition cannot ask how many items of an iterable satisfy something, nor what the total, the smallest, the largest or the mean value over them is. Add five aggregate expressions: `for count`, `for sum`, `for min`, `for max` and `for avg`, written like the quantified `for` but with the operation where the quantifier goes.

`count` yields how many iterations satisfy their body. `sum`, `min`, `max` and `avg` take a numeric body and yield the total, the smallest, the largest and the mean of its values. `avg` is always a float, whatever its body. Integer results wrap around on overflow, and `avg` divides that same wrapped total by the number of iterations that contributed.

The five operations also aggregate over a set of patterns, written `for sum of them : ( # )` or over any pattern set the quantified form accepts.

An aggregate is an expression that yields a number, usable wherever a number is. That includes places another loop evaluates while it is running, such as its quantifier, its range bounds, or an item of the tuple it iterates, and an aggregate sitting in one of those must leave the loop around it working.

An iteration whose body has no value contributes nothing. When nothing contributes at all, `count` and `sum` are 0, while `min`, `max` and `avg` have no value.

The names of the five operations are only meaningful written directly after `for`. Anywhere else they are ordinary identifiers, so a parenthesized one supplies a quantifier the way any other expression does.
