# Exact-version fairness analysis

Status: `pass; calibration 0/10`.

Repository pin: `06a0599933114f36efe59667cd80ee0246a1a882`.

Artifact binding: `meta.md` `1f5811dd46c`, `test.patch` `6056f8559e83`,
`solution.patch` `b48dd4dba68b`, and Dockerfile `df08c4461aa6`.

## Rejection-predicate audit

| Predicate family | Grounding | Decision |
|---|---|---|
| missing public method | explicit signature in the prompt | retain; reflection keeps pristine failure inside the named case |
| foreign transfer origin | explicit same-origin rule | retain; require rejection and unchanged zone, not rejection before `run()` |
| current and AXFR response handling | explicit producer-mode contract and existing mode APIs | retain; current proves at least one run, not an exact call count |
| chain start, boundary SOAs, declarations, continuity | explicit prompt and RFC 1995 framing exposed by `Delta` | retain; no validation order or message text |
| RFC 1982 progression | explicit prompt and repository `Serial` semantics | retain |
| delete before add | explicit prompt and RFC 1995 ordering | retain; DNS record identity remains TTL-insensitive |
| origin and class on both sections | explicit prompt plus `Name.subdomain`/`getDClass()` | retain |
| absent staged deletion | explicit strict policy | retain; exact `Record` equality is repository semantics |
| final SOA/NS validity | explicit prompt and existing `Zone` constructor invariant | retain |
| derived lookup/accessor/output state | explicit prompt and public `Zone` APIs | retain |
| delta-list and record ownership | explicit prompt and public mutable lists | retain; compare values, not object-copy strategy |
| rollback after receive or staged failures | explicit all-failure rollback rule | retain |
| single-read publication atomicity | explicit concurrency clause and documented `Zone` locking | retain; no iterator or cross-call snapshot demand |
| 10-second latch timeout | deadlock/watchdog only | retain; not a product-performance limit |
| offline Maven, writable tree, JUnit XML | repository/evaluator environment | retain |

## Fixture and architecture neutrality

Transfers are parsed through dnsjava's real DNS wire parser and existing
`ZoneTransferIn` handler seam. Tests do not reflect into private `Delta` state.
The package-local transfer constructor/client hook follows existing repository
test practice and only supplies deterministic wire messages. Mutable public
delta lists are used only where the public ownership contract itself is tested.

Assertions use `Record` equality, public zone accessors, lookup results,
iteration, and master output. The wildcard answer is checked semantically by
its returned address because dnsjava legally rewrites the owner to the query
name. No assertion fixes map type, record ordering beyond public master/iterator
semantics, copy strategy, lock identity, batching, exception wording, or source
layout.

The concurrency probes use latches and a record subclass to pause a writer
inside repository-supported record access. A single exact lookup during that
pause must yield a whole old or new RRset. Copy-on-write, a single outer lock,
or another atomic publication mechanism can pass. Weak iterators and separate
reads are explicitly outside scope.

## Replay evidence and authoring correction

The reference canonical-map implementation and two materially different staged
list/map implementations pass all seventeen feature cases and 121 selected
existing tests. The direct per-record implementation reaches the same named
tests and fails behaviorally rather than through compilation or startup.

An early test demanded that a foreign-origin transfer never be run. That
prescribed private validation order, so the assertion was removed. The current
test requires only the promised rejection and full rollback. A prior exact-one
run assertion for current mode was similarly loosened to at-least-one execution.
No arbitrary malformed bytes, private list encoding, short performance deadline,
or one private architecture remains.

## Verdict

`Pass` for the exact immutable version. Every logically distinct rejection,
wrapper, timeout, and compile/runtime predicate is public, repository-grounded,
or stable Java/Maven behavior. Any artifact or evaluator-path change requires a
fresh fairness audit.
