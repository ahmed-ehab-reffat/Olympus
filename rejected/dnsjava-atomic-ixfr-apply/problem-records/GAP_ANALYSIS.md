# Exact-version gap analysis

Status: `pass; calibration 0/10`.

Repository pin: `06a0599933114f36efe59667cd80ee0246a1a882`.

Artifact binding: `meta.md` `1f5811dd46c`, `test.patch` `6056f8559e83`,
`solution.patch` `b48dd4dba68b`, and Dockerfile `df08c4461aa6`. Full hashes
are in `ARTIFACTS.sha256`.

## Atomic requirement map

| Public requirement | Strongest black-box evidence | Independent boundary |
|---|---|---|
| public `void Zone.applyIXFR(ZoneTransferIn)` | reflective public method lookup inside a named JUnit case | API |
| same origin and executed transfer | foreign-origin rejection with unchanged serialization; current-mode fixture proves execution | ownership/mode |
| current no-op; AXFR/fallback rejected | parsed current and AXFR responses, before/after full zone state | producer mode |
| complete oldest-to-newest chain | two deltas whose first contribution survives the second | chain replay |
| current start, SOA framing, declarations, and continuity | malformed boundary SOAs, declared serial mismatch, and broken adjacency | framing |
| RFC 1982 advancement | valid `0xFFFFFFFF` to `1` transfer | serial domain |
| deletions precede additions | equivalent record delete/add with changed TTL | operation order |
| every record has zone class and is in-origin | add-side origin/class cases and an independently staged wrong-class delete | direction/ownership |
| every delete is present in staged state | later absent deletion after earlier valid work | divergence/rollback |
| final zone has exactly one SOA and at least one NS | last-apex-NS deletion rollback plus constructor-equivalent final state | validity |
| every ordinary read surface reflects the final zone | SOA/NS, exact/wildcard lookup, RRsets/RRSIGs, iteration, and master output | derived state |
| input lists and records remain caller-owned | snapshots of parsed public delta lists and record values | ownership |
| transfer, validation, and apply failures rollback | receive exception, late absent delete, malformed chain, invalid final zone | lifecycle |
| one concurrent read never sees a partial RRset | deterministic delete-side and add-side exact-lookup probes | publication direction |

## Coverage dimensions

Producer modes cover current, IXFR, AXFR fallback, and receive failure. Chain
states cover one and multiple deltas, normal and wrapping serials, the initial
boundary, adjacent boundaries, and the final candidate. Record directions cover
deletes and adds; resource boundaries cover apex, in-origin non-apex,
out-of-origin, and wrong class. Lifecycle coverage distinguishes pre-run
rejection, receive failure, staged validation failure, staged application
failure, invalid final state, successful publication, and a read concurrent
with both removal and addition.

Read surfaces that share the same `Zone` lookup path are grouped, but cached SOA,
cached NS, wildcard resolution, ordinary RRsets, covered-type signatures,
iteration, and master serialization remain separately observed because the
repository implements them through different fields or branches. Node-type and
record-type permutations that use those same paths are not multiplied into
fixtures.

## Gap closure and rejected probes

The first thirteen-case draft left four independently implemented cells open.
The final suite added transfer-receive rollback, delete-side class validation,
delete-before-equivalent-add ordering, and add-side atomic publication. The
first three have isolated mutants that pass the predecessor thirteen tests and
fail only the admitted probe. The direct per-record implementation supplies
repository-backed evidence for the separate addition publication direction.

The following proposed cells were rejected:

- an empty delta or arbitrary null record, because the repository's real
  `BasicHandler` producer cannot emit it;
- an out-of-origin deletion that is somehow already staged, because valid
  `Zone` construction cannot create that state and absent-delete behavior is
  already covered;
- extra SOAs in a section produced only through artificial list mutation,
  because the wire parser already owns framing;
- every RFC 1982 half-range permutation, because these share the same stable
  `Serial.compare` boundary;
- exact exception classes/messages, validation order, staged container shape,
  iterator snapshots, and cross-call generation pinning, because none is a
  public requirement.

## Verdict

`Pass` for the exact artifact version. All public clauses are mapped across
their independently implemented families, directions, lifecycle states,
producer modes, and resource boundaries. Any submission-artifact change
invalidates this audit.
