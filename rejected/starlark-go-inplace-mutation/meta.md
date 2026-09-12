---
Repository: https://github.com/google/starlark-go
Issue: N/A
Commit: 5395d018f003e2a08bfbca6dcb2562acee700f62
Language: Go
Title: Add in-place list mutation: slice assignment, del, sort, and reverse
---
# Add in-place list mutation: slice assignment, del, sort, and reverse

A list slice may appear as an assignment target. `x[i:j] = y` replaces the selected elements with the elements of the iterable `y`, growing or shrinking the list so that a target slice selecting nothing inserts and an empty `y` deletes. When the slice has a step other than one, `y` must supply exactly as many values as the slice selects. Assigning to a slice of anything other than a mutable list is an error.

`del x[i]` removes the element at index `i` from a list, or removes key `i` from a dict. `del x[i:j]`, including a slice with a step such as `del x[::2]`, removes the selected elements from a list. A del target must be an index or slice of a mutable list, or an index of a dict; deleting a bare name or a target of any other type is an error, as is deleting a list index that is out of range or a dict key that is absent. A single `del` may list several comma-separated targets, removed left to right.

`x.sort()` orders a list in place and accepts the same optional `key` and `reverse` keyword arguments as the `sorted` builtin, ordering equal elements stably; `x.reverse()` reverses a list in place. Both return `None`.
