# Keep a tree of the source a parse consumed

The whitespace a parse stepped over, the comments an `ignore` expression swallowed and where each
token came from are gone by the time it returns, so nothing can change one value in a file and leave
the rest.

Add `parse_source(instring, parse_all=False)` and `scan_source(instring)` to `ParserElement`. The
first returns a `SourceNode` for the match, the second one node named `source` over the whole text, a node
per match that takes text. Export `SourceNode` from the package, listed in `__all__`.

The tree has a node for every expression that took part in a match, nested as the grammar nests, the
sequences and alternations the operators build included. A node reports its `name`,
its results name or, without one, its expression's name; its `start` and `end`; the `text` it
matched; the `trivia` skipped just before it; the `skipped` nodes for ignored expressions
inside that trivia, each listed once, whose parent is the node holding them; its `tokens`; its `parent` and `children`; and its `line_number` and `column`,
both counted from one. `walk` yields a node, then everything under it, in source order. `find` gives the first
node of a name in that order, or `None` when there is none, and `find_all` all of them as a list in
that order. `dump` renders a subtree one node to a line in `walk` order, each line naming
the node and where it starts and ends.

`source()` gives back the text a node accounts for, the trivia included. So the root of a parse
returns exactly the text that parse consumed, and with `parse_all`, or from `scan_source`, exactly
the whole text. Text passed over between one match and the next belongs to the `source` node,
not the match that follows. Text skipped after a match is never its trivia. Tabs are not expanded.

An attempt that fails leaves nothing behind, and neither does one made only to see whether a match
is possible, so a losing alternative, and an expression that only looks, ahead or behind, are absent
from the tree. An expression inside `Suppress` keeps its node and its text; only its tokens go. A
parse action may change the tokens of a node but never its text. Either of pyparsing's memoizing modes produces the
same tree.

A node can be rewritten: `replace` puts new text where it matched, `remove` takes it out together
with the trivia before it, and `insert_before` and `insert_after` add text around it, after the
trivia and before whatever follows. `source()` then returns the input with those changes and every other
character as it was, `text` and `trivia` show a replacement and the rewrites below them, while `start`, `end` and `tokens`
go on saying what was parsed. Replacing or removing a node decides for the ones below it; text put
around one keeps them.

Five rules are worth stating twice. A comment stepped over by a repetition attempt that then fails, or by
the walk `parse_all` makes to the end, belongs to no node: no `trivia`, no `skipped`, never twice. A node an expression skipped over is in that expression's `skipped` or among its
`children`, never both. An expression may ask whether another one matches here before parsing it
for real, `try_parse` included, and that ask leaves nothing behind, parse actions on or off,
however often. A parse a parse action starts is its own and adds nothing here, whatever text it
runs over. And a replacement shows in a node's own `text`, while text put around that
node shows in `source()` and in the `text` of the nodes above it, never in its own.
