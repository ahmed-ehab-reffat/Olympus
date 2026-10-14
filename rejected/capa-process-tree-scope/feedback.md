# feedback.md - capa-process-tree-scope (SHELVED at the measure-first spike, 2026-09-29)

Repo mandiant/capa (canonical, 6206 stars, Apache-2.0). Base 497120ff (2026-08-28, every CI job green;
master f3765cdf only adds dep bumps and a rules-submodule sync). Hunt #39 fallback 2
(`worktrees/_hunt/s_0929h39/dossier_capa_h39.md`), tried as the one allowed fallback after
vega-keyed-dataset-reconciliation died on size.

Lane: a `process tree` dynamic scope between `file` and `process`: evaluated at every process over the
union of its own and all descendants' features, tree built from ProcessAddress (ppid, pid) with
self-parent / missing / ambiguous parents as roots and cycles broken, process-scope matches indexed
into the per-process feature set (base discards it, dynamic.py:260/268), tree matches reported only at
minimal subtrees except where a reported match depends on them, visible to file rules, carried by the
dynamic layout (processes without matched calls) and rendered by -v / -vv.

Measure-first spike (`solution.patch`, 5 files, full lane): raw 154, **117 human-effective**. Smoke
probe in olympus-base-python (`probe_tree_scope.py`, NullDynamicFeatureExtractor, 4 processes, 3 levels):
minimal-subtree reporting at pid 200, dependency carve-out keeps the ancestor copy at pid 100 for a
tree rule that `match:`es it, the file rule sees the tree rule, the layout carries the tree root.
test_rules / test_engine / test_match green (data-dependent tests need the malware-sample submodule).

Why under: scope registration is the #2532 span template (20 eff), the renderers and layout are one
branch each (18 eff), and the whole kernel (tree + union + reporting + file visibility) is ~80. Proto
mapping would need a regenerated capa_pb2 and is excluded; even with it the lane stays under 150.
DEAD: machinery-absorbed UNDER-FLOOR (117 vs 250 proceed gate / 200 floor). No problem folder was
authored; exclusivity and six-check were the hunter's (clean) and were not re-run.
