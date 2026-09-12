# UPSTREAM AUDIT - asticode/go-astisub collision-safe merge

Audit date: 2026-08-01. Base/current head is
`52190f1d606f35190d40e86ecb02c31902f30272`, v0.42.0. Repository facts:
701 stars, 130 forks, MIT, active July 2026.

All 142 accessible issues/PRs, full git history/tags, relevant code/tests, and
six recently active/divergent forks were searched for merge/style/region,
collision/duplicate, remap/rebind/rename, clone/alias/donor mutation, and
deterministic ID terms. No equivalent request or implementation exists. A fork's
broken shallow `Clone` experiment does not initialize or close the graph and
does not alter Merge.

The task fits the public mutating Merge API used by README and CLI. It repairs
observable format corruption without adding policy or API surface. Local
similarity exists with generic graph-copy/remap work, but two independent
complete architectures and subtitle-native TTML/SSA/WebVTT semantics distinguish
the implementation space.

Verdict: `proceed`.

