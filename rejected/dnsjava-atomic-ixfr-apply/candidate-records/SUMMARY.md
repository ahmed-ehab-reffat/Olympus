# dnsjava atomic IXFR application - candidate summary

Status: **rejected as previously implemented; archived; calibration closed at 0/10**.

- Repository: [`dnsjava/dnsjava`](https://github.com/dnsjava/dnsjava)
- Pin: `06a0599933114f36efe59667cd80ee0246a1a882` (2026-06-14)
- Production language: Java
- Task type: enhancement
- Rating: **8/10**

## Candidate

Add a public `Zone.applyIXFR(ZoneTransferIn)` operation that runs an
incremental transfer and applies a completed chain of `ZoneTransferIn.Delta`
objects to the existing zone as one atomic update. A current response is a
no-op; an AXFR fallback is rejected so callers can continue to use the existing
full-zone constructor.

Before publication, the operation must validate the transfer origin, current
SOA serial, every old/new SOA boundary, delta-to-delta serial continuity using
RFC 1982 arithmetic, record ownership/class, requested deletions, and the
resulting zone's existing SOA/NS invariants. Any transfer, validation, or apply
failure leaves the observable zone unchanged. Successful publication must keep
SOA/NS caches, wildcard lookup state, RRsets/RRSIGs, iteration, and concurrent
readers coherent without mutating the transfer's record lists.

## Why it survived

- `ZoneTransferIn` already parses and exposes IXFR deltas, while `Zone` can
  only construct from AXFR and otherwise offers per-record locked mutations.
  There is no operation joining those two mature surfaces.
- Six exact all-state issue/PR queries, fetched branches, full local source and
  history, releases, and recent commit subjects found no application feature or
  owner.
- The oracle is public and state-based: compare the updated zone with the
  corresponding complete zone, then exercise lookups, iteration, serial state,
  and rollback after malformed chains.
- Plausible shortcuts fail independently: apply only the last delta, compare
  serials as ordinary integers, mutate before validation, ignore absent
  deletions, update the SOA but not cached state, or expose a partially applied
  zone to readers.

## Measured trial

Two clean disposable implementations used different staged representations and
converged on a one-file validate/stage/publish change of 110 and 114 production
additions. Their focused suites passed 5/5 and 3/3 respectively; their complete
offline suites passed **1,744** and **1,742** tests with 29 skips and no
failures/errors. Both passed formatting and diff checks.

A 22-line direct-loop mutant applied each delete/add through the existing
per-record methods. The reader probe rejected it on all four attempts, observing
partial sizes between 1,436 and 1,482 in a 1,500-record RRset. The same probe
passed both staged implementations.

## Promotion result

The candidate was promoted on 2026-08-11 to
[`problems/dnsjava-atomic-ixfr-apply/`](../../problems/dnsjava-atomic-ixfr-apply/).
Its exact 17-case feature lane produces seventeen named pristine failures and
passes the reference plus two legitimate staged architectures. The selected
121-test base lane and 1,756-test combined reference tree pass; exact
environment, gap, fairness, and false-positive gates are recorded with frozen
artifact hashes.

## Remaining constraints

The solution is compact and naturally converges on staged publication. Any
future revision must not prescribe the staging container, weak-iterator
snapshot behavior, cross-call reader generations, or private `Delta`
construction. Strict missing-delete failure and AXFR-fallback rejection remain
explicit public policies. The user later reported a prior-implementation
rejection, so the exact task is terminal and calibration closed without a run.
