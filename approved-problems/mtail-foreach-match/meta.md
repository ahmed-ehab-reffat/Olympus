# Add foreach iteration over line matches and metric entries

Extend the mtail program language with a `foreach` statement.

`foreach /pattern/ { ... }` runs its block once for every match of `pattern` on the current line, taken left to right. Matches do not overlap, and an empty match immediately following the previous match is skipped. Inside the block the capture groups of `pattern` are bound to the current match. `foreach /pattern/ in expr { ... }` matches within the string value of `expr` instead of the whole line. Any foreach form may take an optional trailing `else { ... }` block that runs when the loop performs no iterations; a foreach that performs no iterations also counts as unmatched, so a following `otherwise` in the same scope runs.

`foreach id in metric { ... }` runs its block once for each stored entry of `metric`, in ascending lexicographic key order, with `id` bound to the key; the metric must have a single dimension. `foreach key, value in metric { ... }` also binds `value` to the entry's value. The keys are fixed when the loop begins, so entries added inside the block are not visited. Adding `limit n` to either metric form visits only the `n` entries with the largest values, in descending value order, breaking ties by ascending key. `foreach id in fields(expr, /sep/) { ... }` splits the string `expr` on the separator pattern, keeping empty fields, and binds `id` to each field.

`matchindex()` returns the zero-based iteration index of the innermost enclosing foreach and is valid only inside a foreach body, not in an else block (which runs only when there were no iterations to index). `matchcount(/pattern/)` returns the number of matches of `pattern` on the current line.
