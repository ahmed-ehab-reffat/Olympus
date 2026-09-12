# Keep the key order of objects read from JSON

Add an `--ordered-keys` option which keeps the key order of objects read from JSON and of objects
the query builds, together with a `keys_unsorted` builtin and a `--sort-keys` (`-S`) option. Input
which is rejected now is still rejected: a cut-short object or array is an error, not the end of
the input. An object keeps no order unless the option asked for it.

Printing an object as JSON prints its keys in the order it keeps, which is also the order its
members are visited in. `-S` sorts the keys of every result it prints as JSON, at every depth.

A key the program creates goes to the end, including when the assignment is what creates the
object it goes into, and assigning to a key which is already there leaves it where it is. `a + b`
appends b's new keys in b's order, and `a * b` does the same at every depth. Where the same key is
named twice in the text, the key stays where it first appears and takes the later value.

`to_entries` gives the entries in order and `from_entries` builds in the order it is given,
however the object is put together. `keys_unsorted` is the one that gives an object its own order.
A value a builtin hands back keeps no order of its own, and an object which keeps no order of its
own counts as sorted wherever the order is used.

`tojson`, `@json` and `fromjson` keep it.