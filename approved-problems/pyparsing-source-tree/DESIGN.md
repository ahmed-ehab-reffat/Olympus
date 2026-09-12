# DESIGN — pyparsing-source-tree

## 1. Title

Keep a tree of the source a parse consumed (pyparsing, Python, MIT, 2478 stars, base
`d3388aaf5c60d1069b7294a743ccd0e7c87a1d1d`, default branch last commit 2026-07-19).

## 2. Shape

O-Pipeline-hard / capability-add. A second product of the parse, built by instrumenting the one
function every expression goes through, plus a node type that owns the text and can rewrite it. The
difficulty is speculative-state discipline: pyparsing tries far more than it keeps, and only what it
kept may reach the tree.

## 3. Why this pick

This is the second pick on this repo in this task. The first,
`rejected/pyparsing-incremental-streaming`, was built end to end and died at the similarity gate as
a derivative of an older chunked-parsing submission. The core here is deliberately far from the four
capability classes now known to be taken on parser libraries: enumerating alternative parses (our
own approved submission), incremental or chunked input, session isolation, and error recovery with
completions.

- **Real gap.** A parse returns tokens. The whitespace it stepped over, the comments an `ignore`
  expression swallowed and the origin of each token are gone, so nothing built on pyparsing can
  change one value in a file and leave the rest byte for byte.
- **Invented.** Nothing external defines what a pyparsing tree should contain or when a rejected
  alternative may appear in it.
- **Exclusivity.** Issue and PR searches for lossless, concrete syntax tree, round trip, preserve
  comments and unparse return nothing on the canonical repo.
- **Baseline to preserve.** The hook sits on `_parse`, the hottest path in the library, and the
  ordinary path has to stay untouched, including its stack depth.
- **Environment.** Pure Python, zero runtime dependencies, whole suite green in 60s offline.

## 4. Public surface (pinned in meta.md)

- `ParserElement.parse_source(instring, parse_all=False) -> SourceNode`
- `ParserElement.scan_source(instring) -> SourceNode` (one node named `source` over the whole text)
- `SourceNode`: `name`, `start`, `end`, `text`, `trivia`, `skipped`, `tokens`, `parent`, `children`,
  `line_number`, `column`, `source()`, `walk()`, `find()` (first in source order or `None`),
  `find_all()``find_all()` (a list in source order), `dump()`, `replace()`,
  `remove()`, `insert_before()`, `insert_after()`.

## 5. The contract

1. **Shape.** A node for every expression that took part in a match, nested as the grammar nests.
2. **Losslessness.** `source()` returns the text a node accounts for, its trivia included, so the
   root gives back exactly what the parse consumed, and the whole text under `parse_all` or from
   `scan_source`. Tabs are not expanded.
3. **Only what was kept.** An attempt that failed, and one made only to see whether a match is
   possible, leave nothing. `Suppress` keeps its node and its text. A parse action changes tokens,
   never text. Memoized parsing gives the same tree.
4. **Rewriting.** `replace`, `remove`, `insert_before` and `insert_after` change one node's span;
   everything else comes back unchanged, and the outermost rewrite wins.

## 6. Solution outline

`pyparsing/core.py`

- `_building_tree`, a context manager that installs a closure over the builder and the real
  `ParserElement._parse` in its place while a tree is being built. It opens a frame, calls the real `_parse`, and on success turns the frame into a node; on
  any exception it drops the frame. This is why a rejected alternative leaves nothing.
- One line inside `_parseNoCache` pushes `tokens_start` onto a stack, so a node knows where its
  match began as opposed to where its attempt began. A stack rather than a slot, because a parse
  action can start a parse of its own and a memoized attempt pushes nothing at all.
- `parse_source` and `scan_source`: install the builder, run, restore. The wrapper is a swap rather
  than an edit to `_parseNoCache` so ordinary parsing keeps its exact stack depth; splitting the
  function instead cost one frame per element and broke the repo's deep-recursion example.

`pyparsing/sourcetree.py`

- `SourceNode` holds `_parts`, a mix of child nodes and the strings of its own text no child covers,
  so `source()` is assembled from the tree rather than sliced out of the input. A node's trivia is
  held the same way, so an ignored expression rewritten through `skipped` shows up too. Rewriting is a
  replacement, a removal or text added around, applied where the parts are joined.
- `_TreeBuilder.keep` decides what belongs to a node: children that end at or before the match are
  the ignored expressions skipped on the way in and become `skipped`; children inside the span are
  content; children past the end were skipped while trying to continue and belong to nobody. A memo
  of parts per (expression, location, end) covers memoized attempts, which run nothing and report
  nothing; the end is in the key because a growing left recursion re-parses the same place.

## 7. File footprint

| file | raw + | human-effective |
|---|---|---|
| pyparsing/core.py | 129 | 91 |
| pyparsing/sourcetree.py | 292 | 173 |
| pyparsing/__init__.py | 2 | 2 |
| total | 430 | **271** |

## 8. Test outline

`tests/test_source_tree_be9b9d.py`, 136 tests in eleven groups: tree shape, round trip, skipped text,
attempts that do not count, what the tree keeps, memoized parsing, rewriting, failures. 136/136 fail
on base at run time, 136/136 pass with the solution. A base class resets pyparsing's global defaults,
because other suites in the repo leave them changed.

## 9. Traps (mutation-proven, see feedback.md)

| # | trap | class | kills |
|---|---|---|---|
| 1 | a node starts where the attempt started, not where the match did | S4 | 67 |
| 2 | the text of a node is read off the input instead of built from the tree | S3 | 18 |
| 3 | scanning reports the matches and forgets the text between them | S3 | 14 |
| 4 | ignored text is treated as part of what the node matched | S2 | 11 |
| 5 | an attempt that failed keeps the nodes it built | S1 | 3 |
| 6 | text skipped past the end of a match is counted as part of it | S2 | 3 |
| 7 | replacing a node drops the text skipped before it | A8 | 7 |
| 8 | a memoized attempt gives a node with nothing under it | S5 | 1 |
| 9 | removing a node leaves the text skipped before it behind | A8 | 3 |
| 10 | a rewrite below a rewritten node still shows | S2 | 5 |
| 11 | parsing the whole text stops at the last match | A9 | 3 |
| 12 | extending the root for the whole text drops the ignored expressions it skipped | S2 | 1 |
| 13 | a memoized attempt reports the position the attempt began at | S5 | 1 |
| 14 | dump renders only the node it is asked about | A8 | 1 |
| 15 | the node type is importable but not in the export list | A8 | 1 |
| 16 | walk reports a node after the ones under it | A8 | 5 |
| 17 | dump reports where a node ends now, not where it ended when parsed | A8 | 1 |

## 10. Predicted difficulty

The contract reads like a data structure and implements like speculative-state bookkeeping. Three
separate discoveries are needed: that a node's own start is not the position its attempt began at,
that pyparsing hands ignored expressions to whichever element skipped them rather than to the text
they sit in, and that the ordinary parse path must keep its stack depth. The shape a solver
self-tests, a flat grammar over text with single spaces, passes under every wrong version.

## 11. Fairness

Every asserted behavior traces to a meta sentence: the two entry points, the node surface, the
round-trip law, the four "only what was kept" rules, and the four rewriting rules. Nothing pins an
error message or an internal attribute. The one place the tree's shape is pinned exactly is a two
level grammar whose nesting the description's first rule fixes.
