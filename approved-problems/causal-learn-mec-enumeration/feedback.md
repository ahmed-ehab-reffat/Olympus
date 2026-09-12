# feedback — causal-learn-mec-enumeration

## Why this exists

Task42's slot is pinned to `py-why/causal-learn`, and Test Fairness confirmed it three times
by quoting `setup.py:7-23` of that repo. A music21 submission built for the same slot was
therefore unevaluable no matter how clean its contracts were, so this problem is authored
against the repository the checker actually pins.

## The feature

`causallearn.utils.MECCheck.mec_check` only answers whether two DAGs share a Markov
equivalence class. Three new modules describe and walk the whole class:

- `MECStructure` reads a partially directed `GeneralGraph`: directed and undirected edges,
  chain components, colliders, acyclicity, and the closure of the four Meek rules.
- `MECEnumeration` lists every consistent extension, counts them, picks the first, checks
  membership, and derives compelled edges, the essential graph and per-edge orientation
  counts. `mec_of_dag` and `same_class` give the classical essential graph of a DAG.
- `MECTraversal` walks the class by covered edge reversal: covered edges, one reversal,
  neighbours, the reachable set, reachability, and a shortest reversal path.

The two halves meet at an invariant worth the whole design: the set reached by covered edge
reversals equals the set produced by enumeration, so a bug in either shows up as a mismatch.

## Fairness discipline carried over

Both earlier Test Fairness reports in this slot flagged the same class of defect, so every
contract is stated up front rather than left to the reader:

- the previous causal-learn attempt lost 22 tests to pinned nested tuple shapes, unstated
  ordering, and exceptions raised by functions the prompt never named as validators;
- the music21 attempt lost 21 to unstated return types before those were stated, after
  which the checker dropped every one of them.

So meta.md names the return shape of every routine, the sort order and tie-break of every
list, the single exception class, and every refusal. Where a graph comes back it says so.

## Scope of base mode

The repository's own suite does not run clean out of the box: `TestPNL` and `TestDAG2PAG`
import `torch`, `TestFAS` fails an assertion while importing a benchmark file, `TestCAMUV`
fails to import, several tests raise `FileNotFoundError` from relative data paths, and the
kernel independence tests are slow and randomized. Base mode therefore runs the five graph
and structure files that are green, fast and deterministic from the repository root, which
are also the files closest to the change.

## Attempt history

### Round 1 (2026-08-10) — authored

- Solution: 3 new files, no edits to existing files, 640 raw added, 443 human-effective LOC.
- Tests: 115 methods, all failing on base with named nodes, all passing with the solution.
- Two defects found while building: the collider check rejected forks as if they were
  colliders, which made a three node chain report two members instead of three; and
  `mec_size` first factorised over chain components, which is only valid when no directed
  edge crosses a component, so it now counts the members it enumerates.

### Round 2 (2026-08-10) — Test Fairness 1 of 115, fixed

The check came back FAIL on a single test, and it was right. meta.md said both that
`is_cpdag` answers False for a graph carrying a cycle and that all four routines in that
group refuse a graph with no member, having already said a cyclic graph has no member. Two
readings, one test pinning one of them. The sentence now names the three that refuse and
says `is_cpdag` answers False, matching the predicate semantics the rest of the family uses.

All five coverage suggestions taken, and one exposed a real defect:

- `MECTraversal._as_dag` read the adjacency without validating first, so a CIRCLE endpoint or
  a repeated node name slipped past every traversal entry point. It now validates like the
  other two modules, and the suite exercises endpoint and name validation through enumeration
  and traversal, not just the structure helpers.
- `reversal_path` picked its predecessors by first-discovery order in a breadth first walk,
  which is not the lexicographically first shortest run meta.md promises. It now measures
  distances from the target and steps greedily to the smallest state that shortens the
  remaining distance. The new tie-break test would have failed on the old code.
- Added tests for node-order mismatch on the extension check, `same_class` and the traversal
  APIs, and for undirected or cyclic input refused by `mec_neighbours`, `mec_from_traversal`,
  `reversal_path` and `reversal_distance`.

Tests are now 127, human-effective LOC 464, meta.md 855 words.

### Round 3 (2026-08-10) — quality check WARNING, last gap closed

The quality check raised a WARNING naming four untested nuances. Three were already closed in
round 2: the reversal path tie-break, traversal refusals beyond `covered_edges`, and the
node-order refusal on `is_consistent_extension`. The fourth was real and is now closed:
`mec_neighbours` was only exercised where there is one neighbour or none, so its stated
ordering was never checked. A complete order on three nodes has two covered edges, and the
suite now pins both the order of the two neighbours and the count against `covered_edges`.

The Test Fairness report supplied alongside it is the round 1 run: it counts 115 tests where
the suite now has 129, flags the `is_cpdag` wording that round 2 rewrote, and repeats the
five coverage suggestions round 2 implemented. Re-running it against the current artifacts
should clear it. Tests are now 129, human-effective LOC 464, meta.md 855 words.

### Round 4 (2026-08-10) — 2 of 129 unfair, both from my own round 2 fix

The current run flags exactly the two node-order tests round 2 added while answering the
node-order coverage suggestion. The reading is right: meta.md said `same_class` and the
traversal pair routines refuse two graphs whose node *names* differ, and those tests pass
identical names in a different order. Only `is_consistent_extension` mentioned order, and
`GeneralGraph.__eq__` is permutation aware, so an order-insensitive implementation was just
as defensible. The clause now reads "differ in name or in order" in both places, matching
the implementation and the wording `is_consistent_extension` already used.

That is worth writing down: adding a test to satisfy a coverage suggestion can introduce an
unfairness of its own if the behavior it pins was never stated. The suggestion asked for
node-order coverage; it did not say the prompt already licensed it.

All four new coverage suggestions taken:

- a graph with no member that carries no cycle: A -> D, B -> C with C - D undirected, where
  either orientation of C - D makes a fresh collider. Found by search over four node graphs.
  meta.md now says such a graph gives an empty list and a size of 0 while `canonical_dag`
  refuses it, and the suite pins all six routines on it.
- `same_class` with a cyclic argument in either position.
- `reverse_covered_edge` on undirected and cyclic input.
- `reversal_distance` between two classes.
- two further illegal endpoint pairs. A third, CIRCLE-TAIL, turned out not to be
  constructible: `GeneralGraph` stores it as no edge at all, so there is nothing to refuse.

Tests are now 136, human-effective LOC 464, meta.md 896 words.

### Round 5 (2026-08-10) — four coverage suggestions, one real ordering bug

The text-ordering suggestion found a genuine defect. meta.md says members come back ordered
by their lists of directed edges, but `mec_dags`, `mec_neighbours`, `mec_from_traversal` and
the tie-break inside `reversal_path` all sorted tuples of node INDICES. Those agree with the
stated order only while index order happens to match text order, which it does for A, B, C
and does not for X2 and X10, where text puts X10 first. All four now sort by the name lists
they are documented to sort by. This is the second time a coverage suggestion exposed a real
bug rather than a missing test.

Also taken:

- names such as X2, X10 and reverse-inserted nodes across edges, components, colliders and
  enumeration, so nothing can pass by sorting on the node index;
- duplicate node names through a traversal entry point;
- one more illegal endpoint pair, CIRCLE-ARROW. NULL, STAR, TAIL_AND_ARROW and
  ARROW_AND_ARROW cannot be reached: `GeneralGraph` stores them as no edge at all, so there
  is nothing for validation to refuse. Only the CIRCLE and arrow-arrow forms are exposable;
- the path test now checks that the edge which flipped at each step was covered in the graph
  before it, not merely that two directed edges changed.

`ruff --select F` is clean on all four added files. The wider default rule set flags the
repository's own `MECCheck.py` for the same items (module naming, typing.List, percent
formatting), so those are house style rather than project rules and were left alone.

Tests are now 144, human-effective LOC 473, meta.md 896 words.

### Round 6 (2026-08-10) — three coverage suggestions, one needing the prompt first

Two of the three asked for tests of behaviour meta.md had never stated, which is the round 4
trap: node order and non-mutation were promised only for `mec_dags` and `meek_closure`, not
for `essential_graph`, `mec_of_dag`, `canonical_dag`, the neighbours or a reversed graph. One
sentence now covers all of them: every graph given back carries the same nodes in the same
order as the graph it came from, and no routine changes a graph it is given. The same
sentence also states that a directed edge may be written with the arrow at either end, which
the first suggestion needed.

Taken:

- an `Edge` built as (ARROW, TAIL) is accepted and reported as the child-to-parent direction
  it means, and both written orders agree;
- text ordering through the traversal too: `covered_edges`, `mec_neighbours` and the
  shortest-path tie-break on X2, X10 and X9, where index order and text order disagree;
- node order preserved by `meek_closure`, `essential_graph`, `mec_of_dag`, `canonical_dag`,
  `reverse_covered_edge`, `mec_neighbours` and `mec_from_traversal`, and non-mutation checked
  on both the enumeration and the traversal side.

Tests are now 155, human-effective LOC 473, meta.md 927 words.

### Round 7 (2026-08-10) — three coverage suggestions, all already licensed by the prompt

Unlike round 6 none of these needed a prompt change; all three behaviours were stated.

- `is_reachable` on an undirected argument in either position, and `reversal_distance` on a
  cyclic argument in either position and on a node-order mismatch. The prompt applies those
  refusals to every traversal routine; they were only reached through neighbouring APIs.
- The rule 3 and rule 4 fixtures now assert the complete directed and undirected lists rather
  than only that A -> B appears. Before pinning them I checked every edge each closure leaves
  undirected against all four stated rules: in both fixtures nothing points into C or D, so
  no rule can reach A - C or A - D, and the full result is forced rather than incidental.
- Malformed endpoints and repeated names through `meek_closure`, `essential_graph` and
  `reversal_path` in both argument positions, so the validation contract is checked at one
  entry point per module rather than only where it was convenient.

Tests are now 164, human-effective LOC 473, meta.md 927 words.

### Round 8 (2026-08-10) — three coverage suggestions, all stated already

- non-`GeneralGraph` arguments through `covered_edges`, `mec_from_traversal`, `is_reachable`
  and `reversal_path`, so the "anything else is refused" clause is checked on the traversal
  side too;
- `reverse_covered_edge(dag, parent, child)` when only the opposite arrow exists, which the
  prompt covers as a missing edge;
- the full `mec_from_traversal` order asserted directly on X2, X10, X9, where index order and
  text order disagree, instead of only comparing it against the enumeration. That matters
  because the two were made to agree by construction, so comparing them cannot catch a shared
  ordering mistake; the round 5 index-order bug was exactly that kind.

Tests are now 167, human-effective LOC 473, meta.md 927 words.

### Round 9 (2026-08-10) — two coverage suggestions, both needing the prompt first

Both landed on genuinely unstated corners, so each got a clause before it got a test.

- `is_consistent_extension` was specified entirely in terms of its first argument. What it
  does when the graph it is measured AGAINST has a cycle or no member was never said, and the
  implementation answers False for both. The clause now covers that case explicitly, next to
  the existing False-rather-than-refuse list.
- A `GeneralGraph([])` was not covered at all. It reads like any other graph: no edge, no
  component, no collider, a directed acyclic graph, and a class holding the one member that
  is itself. That is now one sentence in the prompt and one test per module, including the
  preserved empty node list on every derived graph.

This is the third round where a coverage suggestion pointed at behaviour the prompt had not
licensed. The pattern is worth stating plainly: a suggestion asks for a test, and adding that
test without first adding the clause converts an advisory note into a fairness failure. Check
whether the prompt says it before writing the assertion.

Tests are now 173, human-effective LOC 473, meta.md 984 words.

### Round 10 (2026-08-10) — three coverage suggestions, all stated already

- Near misses for Meek rules 2, 3 and 4, matching the rule 1 one that was already there. Each
  removes one prerequisite: no directed path for rule 2, adjacent witnesses for rule 3, a
  missing second witness for rule 4. All three assert the complete closure. The rule 4 fixture
  is worth a note: dropping the A - D edge also lets rule 1 orient C -> A, because D -> C has
  D non-adjacent to A. That is forced by the stated rules, so the test pins the whole result
  rather than pretending the graph stands still; the point it makes, that A - B is not
  oriented, survives intact.
- An existing collider kept while a new one is refused: A -> B <- C with B - D undirected. Only
  B -> D avoids a second collider at B, so the class has one member and it still carries the
  original collider. This separates "no NEW collider" from "no collider", which nothing tested
  before.
- `canonical_dag`, `mec_of_dag` and `reversal_path` on the empty graph, checked for their own
  return values rather than through the surrounding class behaviour.

Tests are now 179, human-effective LOC 473, meta.md 984 words.

### Round 11 (2026-08-10) — two coverage suggestions, one answered differently than asked

The endpoint suggestion asked for refusal cases covering NULL, STAR, TAIL_AND_ARROW and
ARROW_AND_ARROW. A sweep of all 40 pairs involving those four values shows every one of them
leaves the adjacency matrix at (0, 0): `GeneralGraph` stores no edge at all, so nothing
reaches validation and there is nothing to refuse. Writing an `assertRaises` there would
assert a behaviour the code cannot have. The suite now asserts what is actually true and
worth knowing, that such a graph is accepted and reads as carrying no edge, is a directed
acyclic graph, and puts each node in its own chain component. Only the CIRCLE forms and
arrow-arrow are representable as an invalid pair, and all five of those are already refused.

The non-mutation suggestion is taken as asked: `reverse_covered_edge` on a single-edge graph,
and `reversal_path`, `reversal_distance` and `is_reachable` on two graphs that differ, with
both arguments checked afterwards rather than one aggregate fixture.

Tests are now 182, human-effective LOC 473, meta.md 984 words.

### Round 12 (2026-08-11) — alignment ERROR, caused by round 11

The alignment check failed on a contradiction I wrote myself last round. meta.md said any
edge with a pair of endpoints outside tail-arrow and tail-tail is refused, a blanket rule,
while the round 11 test asserts that a NULL, STAR, TAIL_AND_ARROW or ARROW_AND_ARROW edge is
accepted and reads as no edge at all. Both statements cannot hold.

The behaviour is right and the wording was wrong. Those endpoint values never reach the new
code: `GeneralGraph` stores nothing for them, so the graph genuinely holds no such edge and
there is nothing to refuse. The rule now reads as a rule about the edges a graph HOLDS, and
adds that a pair the graph cannot store leaves no edge behind. The five representable invalid
pairs, the four CIRCLE forms and arrow-arrow, are still refused exactly as before.

Worth recording next to the round 4, 6 and 9 note: a coverage suggestion can also push a test
that contradicts an existing clause rather than merely going beyond it. Round 11 answered the
suggestion honestly, by testing what the code can actually do, but did not go back and check
that the prompt still described it. Both directions need the same check.

meta.md is 999 words with a longest paragraph of 127; the intro was split in two and
compressed to hold the new sentence inside the limit. Tests unchanged at 182.

### Round 13 (2026-08-11) — three coverage suggestions, one needing the prompt first

The `meek_closure` suggestion was the right kind of question: the prompt defined closure for a
validated mixed graph and never said what a directed cycle does there. The implementation
accepts it, keeps the cycle and still orients whatever the rules reach, which is the useful
behaviour, since closure is a rewriting step and not a membership test. That is now one clause
in the prompt and two tests: a bare cycle survives untouched, and a cycle with an undirected
edge hanging off it still gets that edge oriented by rule 1.

The other two were already licensed:

- every exported routine of all three modules now sees a repeated node name and a non-graph
  argument, in both positions for the two-graph routines, rather than one representative per
  module;
- every intermediate graph of a three-step reversal path is checked for node order, not only
  the endpoints.

meta.md stayed inside the limit at 994 words by tightening six sentences elsewhere to pay for
the new clause. Tests are now 191, human-effective LOC 473.

### Round 14 (2026-08-11) — quality WARNING was a hypothetical, no change

The only flag was that the tests might name `Endpoint` members the repository does not have.
It has all seven: `git show <base>:causallearn/graph/Endpoint.py` defines TAIL, NULL, ARROW,
CIRCLE, STAR, TAIL_AND_ARROW and ARROW_AND_ARROW, and a run inside the image against a clean
checkout of the pinned commit prints them and passes the seven endpoint tests. Guarding those
cases with getattr, as the note suggests, would only weaken assertions that provably hold, so
nothing changed. The other three checks came back clean.

### Round 15 (2026-08-11) — 2 of 129 unfair, an ordering clause that stopped one word short

Both flags are the same gap. meta.md said every list of names or of pairs comes back sorted,
which covers edges and components but not the collider triples `v_structures` returns, and two
tests compare that list with ordered equality. The checker offered the choice explicitly:
state the outer order or assert membership order-insensitively. Stating it is better, because
the routine really does sort and an order-insensitive assertion would stop catching a
regression in it. The clause now reads "of names, of pairs or of triples", one word wider,
and both tests are licensed unchanged.

Worth noting how the gap arose: the sentence was written when the only list-returning routines
gave names and pairs, and `v_structures` was added later without widening it. A clause that
enumerates shapes has to be revisited whenever a new shape is returned.

Both other coverage suggestions taken: `is_consistent_extension` and `same_class` now see a
repeated name and an unsupported endpoint in either operand, and `reverse_covered_edge` sees
both as well.

Tests are now 195, human-effective LOC 473, meta.md 996 words.

### Round 16 (2026-08-11) — a genuinely reachable invalid state, found by suggestion

The multi-edge suggestion was the sharper of the two, and it was right. Round 11 concluded
that TAIL_AND_ARROW and ARROW_AND_ARROW cannot reach the new code because `GeneralGraph` will
not store them when they are supplied directly. That is true of a single `add_edge` call and
false of two: adding A -> B and then A <-> B leaves the matrix at (5, 4), a stored combined
edge. The validation already refuses it, so nothing changed in the solution, but the state was
reachable and untested, and the round 11 note in this file overstated the case. The suite now
builds that graph in both construction orders and checks the refusal reaches all three
modules. It also pins the harmless neighbour of that case, adding the same edge twice in
opposite written orders, which leaves one directed edge.

The second suggestion is the validation-versus-predicate distinction on the candidate of
`is_consistent_extension`: a candidate holding an unsupported endpoint pair raises, while a
candidate that is merely unfinished returns False. Both are stated; they are now asserted side
by side in one test so the difference is visible.

Tests are now 199, human-effective LOC 473, meta.md 996 words.

### Round 17 (2026-08-11) — 6 of 10 Nova, hardened with a scale clause

60 percent is far over the 40 percent cap. The suite was broad but every routine was
independently reachable by the obvious reading, so the knob to turn was trap strength, not
size.

The change is one clause and no new API. `compelled_edges`, `essential_graph` and `is_cpdag`
were defined as what every member shares, and the obvious implementation lists the class and
intersects it. meta.md now says those three are asked of graphs whose class holds far more
members than could ever be listed, so they must answer without walking it. The definition is
unchanged, so the prompt stays fair; what changes is that the literal reading no longer runs.

Getting the right answer needs two results a solver has to find:

- the compelled edges of a partially directed graph are exactly the directed edges of its Meek
  closure, so the four rules the prompt already defines compute the intersection without ever
  forming it. Verified exhaustively: over all 4096 four-node graphs that have a member, the
  closure's directed set equals the intersection of every member, every time;
- deciding whether a class is empty also cannot enumerate, so the refusal path needs a
  consistent-extension test. The repository ships the same shape in `utils/PDAG2DAG.py`, which
  makes it discoverable, though that routine loops forever on a graph with no extension and so
  cannot be used unguarded.

The two are interdependent: they sit behind the same three routines, and getting the closure
right without the emptiness test still refuses nothing, while the emptiness test alone still
times out. The misdirection is that the prompt's own wording describes the slow path.

Three tests carry it: a 12 node complete undirected graph, whose class holds 479,001,600
members and whose answer is that nothing is compelled; a 10 node clique under a v-structure,
where 11 edges are forced and 36 stay loose; and a 14 node graph with no member at all, which
must still be refused rather than searched. The reference answers each in milliseconds.

Solution changed for the first time since round 5: the three routines no longer enumerate.
All 202 tests pass, human-effective LOC is now 490, meta.md 999 words.
