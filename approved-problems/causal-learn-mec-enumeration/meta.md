---
Title: Add enumeration of the Markov equivalence class of a partially directed graph
Repository: https://github.com/py-why/causal-learn
Commit: 9de1d886b7ab45868819aec7132f79378990f0b6
---

# Add enumeration of the Markov equivalence class of a partially directed graph

`causallearn.utils.MECCheck.mec_check` only says whether two graphs share a class. Add `causallearn.utils.MECStructure` and `causallearn.utils.MECEnumeration` to describe the whole class.

Both read a `GeneralGraph` whose every edge is either directed, one tail and one arrow in either written order, or undirected, two tails. Anything else passed where a graph is wanted is refused, as are repeated node names and any edge it holds with another pair of endpoints. Only the edges it holds are read, so a pair it cannot store leaves nothing to refuse. Every refusal raises `MECException`, which `MECStructure` defines.

Every graph given back carries the nodes of the one it came from, in order, and no routine changes a graph it is given. A graph of no nodes is read like any other: no edge, no component, no collider, a directed acyclic graph whose class holds itself. Every list of names, of pairs or of triples comes back sorted, comparing names as text.

`directed_edges(G)` gives each directed edge as a parent name then a child name. `undirected_edges(G)` gives each undirected edge as a pair of names, smaller first. `chain_components(G)` gives the connected components of the undirected edges alone, each a sorted tuple of names holding every node, so a node touched by no undirected edge forms a component of its own; the components are ordered by their smallest name. `v_structures(G)` gives each collider as a triple: the two parents with the smaller name first and last, the collider between them, counting only parents that are not adjacent to each other by any edge.

`is_acyclic(G)` says whether the directed edges carry no directed cycle, ignoring the undirected ones. `meek_closure` asks for no such thing: it orients what the rules reach and leaves any cycle standing. `is_dag(G)` says whether the graph is acyclic and has no undirected edge. `meek_closure(G)` returns a new graph with the same skeleton in which the four orientation rules of Meek have been applied over and over until no undirected edge can be oriented further: an undirected edge `b - c` becomes `b -> c` when some `a -> b` has `a` not adjacent to `c`; when `b -> m -> c` already runs; when two non-adjacent `m` and `n` both have `b - m -> c` and `b - n -> c`; and when `b - m -> c` and `b - n -> m` hold with `n` not adjacent to `c`.

A member of the class of a graph orients every one of its undirected edges, keeps all its directed edges, has no directed cycle, and carries no collider the graph does not already carry. `mec_dags(G)` returns every member, each a `GeneralGraph` with the same nodes in the same order and only directed edges, ordered by `directed_edges` of each member. `mec_size(G)` is how many members there are. `canonical_dag(G)` is the first member. A graph whose directed edges carry a cycle has no member, and `mec_dags`, `mec_size` and `canonical_dag` refuse it. A graph without a cycle may still have no member, every orientation of it carrying a fresh collider; then `mec_dags` is empty, `mec_size` is 0 and `canonical_dag` refuses it.

`is_consistent_extension(dag, G)` says whether a graph is one of them. It answers False rather than refusing when `dag` still holds an undirected edge, carries a cycle, or has a different skeleton, and equally when the graph it is measured against has a cycle or no member. It refuses only when the two graphs carry different node names, in name or in order.

`compelled_edges(G)` gives the directed edges every member shares, as a parent name then a child name. `essential_graph(G)` returns a new graph with the same skeleton, those shared edges directed and the rest undirected. `is_cpdag(G)` says whether a graph is already its own essential graph, leaving undirected exactly the edges its members disagree on; one carrying a cycle is not.

 `edge_orientation_counts(G)` gives, for each undirected edge, a four part entry: the two names with the smaller first, then how many members orient it from the smaller name to the larger and how many the other way. The entries are ordered by their pair of names. `compelled_edges`, `essential_graph` and `edge_orientation_counts` refuse a graph with no member, while `is_cpdag` answers False for one. The first two and `is_cpdag` are asked of graphs whose class holds far more members than could ever be listed, so they must answer without walking it.

`mec_of_dag(dag)` returns the essential graph of a directed acyclic graph, refusing a graph that holds an undirected edge or a cycle. `same_class(first, second)` says whether two directed acyclic graphs belong to one class, refusing anything `mec_of_dag` refuses and refusing two graphs whose node names differ in name or in order.

Add `causallearn.utils.MECTraversal` as well, which walks the class one edge at a time. A covered edge of a directed acyclic graph is a directed edge whose child has, besides that edge's own parent, exactly the parents of that parent. `covered_edges(dag)` gives them as a parent name then a child name. `reverse_covered_edge(dag, parent, child)` returns a new graph with that one edge turned round, refusing an edge that is missing, that is not covered, or that names a node the graph does not carry.

`mec_neighbours(dag)` returns every graph one such reversal away, ordered by `directed_edges`, and `mec_from_traversal(dag)` every graph reachable by them over and over, in the same order. `is_reachable(first, second)` says whether one leads to the other. `reversal_path(first, second)` returns a shortest run of graphs starting at the first and ending at the second, each one reversal after the one before, choosing among the shortest the run whose lists of directed edges come first, and `reversal_distance` is one less than its length. A path between two classes is refused, as are graphs whose node names differ in name or in order. Every routine here refuses a graph holding an undirected edge or a cycle.
