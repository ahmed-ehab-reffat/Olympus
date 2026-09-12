# Upstream audit — stateful Theta A-not-B persistence

Repository: `apache/datasketches-java`

Pin: `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`

Verdict: no prior implementation or active owner found as of 2026-08-16.

The audit searched 339 locally indexed repositories, all local candidate,
problem, and archive records, 28 fetched DataSketches branches, roughly 4,053
reachable commits, repository source/tests, and exact all-state GitHub issue
and pull-request queries for `ThetaAnotB`, `A_NOT_B`, persistence,
serialization, heapify, and wrap.

No exact issue, pull request, branch implementation, prior Olympus problem,
solver trajectory, or active owner was found. There were no open Theta pull
requests and no open Theta-persistence issue. The only issue combining A-not-B
and serialization terms was issue 599, which concerns unrelated wording around
A-not-B result serialization.

At the pin, `ThetaSetOperationBuilder` explicitly rejects destination memory
for `A_NOT_B`; generic heapify/wrap omit the family; and `ThetaAnotB` has no
serialization or typed wrap API. Sibling union/intersection implementations
establish the public lifecycle but do not implement this feature for A-not-B.

The full trajectory evidence and discriminator implications are recorded in
`DESIGN.md`. This audit permits the exact task; it does not claim future
upstream ownership cannot change.
