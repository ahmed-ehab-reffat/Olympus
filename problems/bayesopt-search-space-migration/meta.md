---
Repository: https://github.com/bayesian-optimization/BayesianOptimization
Issue: N/A
Commit: af8b928212f0eacd1ce20c20be72c1a7b1d8d421
Language: Python
Category: feature-request
Title: Add search-space changes with state migration to BayesianOptimization
---

# Add search-space changes with state migration to BayesianOptimization

Add `BayesianOptimization.set_space(pbounds, fill=None)`, which replaces a running optimizer's search space and keeps what it has learned.

`pbounds` is the complete new space and its order becomes the parameter order. A parameter is identified by its name: names only in the old space are removed, names only in `pbounds` are added, and names in both are kept with their new definition. `fill` gives a value for each added parameter and for nothing else. A missing value, a name that is not an added parameter, or a value the parameter cannot take (a category it does not have, a number outside its bounds, anything that is not a real number for a numeric parameter) raises `ValueError`.

Every registered point is carried by its parameter values. A kept parameter takes the old value in its new definition: a float parameter takes any real number, an integer parameter takes any real number rounded the way integer parameters already round, and a categorical parameter takes a value equal to one of its categories. A point with a value its new parameter cannot take is dropped together with its target and constraint value. Values outside the new numeric bounds are kept but, as with `set_bounds`, do not count for `max`. When the change makes points coincide and duplicate points are not allowed, only the earliest registered one survives; when they are allowed, all are kept.

Carry queued `probe(..., lazy=True)` points, duplicate-check state, and acquisition-function state into the new space under the same rules as registered points. Apply this recursively to nested acquisition functions: preserve `ConstantLiar` pending points and the candidates `GPHedge` scores at its next suggestion. When only some of those candidates can be carried, that suggestion still scores the carried ones, each for the acquisition function that proposed it. A carried point must still be recognized as a duplicate without evaluation. Every acquisition function must keep suggesting in the new space, whatever parameter types it has. When no registered point lies inside the new bounds, `suggest` returns a random point, as it does before anything is registered. Adding a parameter and removing it again leaves the optimizer exactly as it was, down to its further suggestions, and so does moving bounds and back when no bounds transformer is set.

A `SequentialDomainReductionTransformer` takes the new bounds as its global bounds. A kept parameter keeps contracting from where it was and keeps its current reduced window, trimmed as the transformer trims its windows; an added parameter starts as if the transformer had just been set up; a removed one is forgotten. A minimum window given by name applies by name, to added parameters too. A space the transformer cannot work with (a parameter that is not a float, a minimum window wider than a parameter's new bounds, an added parameter a named minimum window does not cover) raises `ValueError`.

If any part of the change cannot be made, `set_space` raises `ValueError` and the optimizer is left exactly as it was.
