# DESIGN - dnsjava atomic IXFR application

Status: **rejected as previously implemented and archived; this trial record is historical**.

## Startup evidence

`PROBLEM_DESIGN.md` and the candidate search protocol were read before this
design. Local history was searched for dnsjava, IXFR, zone transfers, atomic
zone updates, SOA serial chains, and DNS delta application. No prior dnsjava
problem or candidate implementation exists. The local `miekg/dns` screen is a
message-truncation idea in another repository and does not share this stateful
zone-update contract.

Relevant compact records were read from the Calamine, Statig, str0m,
PcapPlusPlus, and RMK problem histories. Representative raw Statig solver
trajectories were inspected where available. They show that rewrite problems
need explicit identity and publication invariants: an implementation may pass
ordinary outputs while losing stable state across repeated mutations. The RMK
and str0m histories likewise separate stage/order/lifecycle failures from
happy-path transformation. Calamine and PcapPlusPlus show that native branch
boundaries and exact framing must be independently observable rather than
multiplied as equivalent fixtures.

Repository inspection at the frozen pin found:

- `ZoneTransferIn.BasicHandler` parses IXFR into ordered public `Delta`
  objects containing start/end serials plus add/delete lists;
- the transfer parser already rejects internal serial desynchronization and
  uses `Serial.compare` for RFC 1982 arithmetic;
- `Zone.fromXFR` explicitly accepts only AXFR;
- `Zone` is documented thread-safe and stores derived `originNode`, `soaRecord`,
  `nsRRset`, and `hasWild` state, but public mutation locks one record or RRset
  at a time; and
- `Zone.validate()` establishes the repository's existing apex SOA and NS
  invariants.

No tests, reference patch, evaluator, or public prompt were created during the
candidate search.

## Resume gate - 2026-08-11

The user selected this 8/10 candidate for the next trial. `PROBLEM_DESIGN.md`
was reread in full before resuming. Searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`,
candidate/problem folders, and archives for dnsjava, IXFR, RFC 1995,
incremental/secondary zones, atomic application, transactions, rollback, and
publication. This existing candidate remains the only local dnsjava/IXFR
record.

The closest direct trajectory analogue is transactional 3D Tiles publication,
not Statig alone. Its current `SUMMARY.md`, trajectory gate in `DESIGN.md`, and
archive manifest were read. Raw `eval-result.json`, `run.txt`,
`solution-patch.patch`, and agent-message streams for the representative pass
and near-pass were inspected directly from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`.

| Evidence role | Raw run | Outcome | Architecture and IXFR design consequence |
|---|---|---|---|
| Legitimate pass | `agent-runs/Nova_Nova_3` | 30/30 focused and 869/869 baseline | It found that finalization wrote directly to the destination, staged a complete candidate, and published only after validation, with backup/restore and owned cleanup. The solution changed two production files with 394 insertions and 33 deletions. For IXFR, the analogue is to build and validate a complete candidate zone before one publication boundary; tests must not prescribe whether that candidate is a `Zone`, a record multiset, or a copied map. |
| Near-pass | `agent-runs/Nova_Nova_2` | 26/30 focused and 869/869 baseline | It independently implemented the full stage/publish transaction but allowed collision failures to escape as plain `Error` instead of the repository's documented `PipelineError`. Its production patch had 420 insertions and 33 deletions. This shows that successful rollback does not subsume adjacent public boundaries such as transfer-mode handling, input ownership, or dnsjava's repository-native error conventions. |
| Broad behavioral failure | unavailable | retained run 1 never executed behavioral tests because required tooling was missing | No environment failure was relabelled as a solver failure and no unrelated broad failure was substituted. |

The pass and near-pass converged on stage-then-publish while differing in
observable error behavior. They support one atomicity discriminator plus
separate DNS state, validation, ownership, and error surfaces; they do not
justify multiplying delta counts or record types as independent depth.

RFC 1995 was also read during the resume. It orders each delta as deletes then
adds, orders sequences oldest to newest, permits condensed histories, and says
an IXFR client should replace its older zone only after every difference has
been successfully processed. That grounds staging and final publication but
does not prescribe dnsjava's in-memory representation.

The frozen upstream pin remains the default-branch head. All-state ownership
queries and the only current remote branch were rechecked; no application
feature or competing patch appeared. Four recent default-history commits are
direct Dependabot-authored dependency updates; no generative coding-agent
author marker was found. This corrects the earlier overly broad statement that
there was no agent marker of any kind.

## Provisional public contract

`Zone.applyIXFR(ZoneTransferIn)` executes a transfer for the zone's origin and
applies an IXFR response atomically. An up-to-date response changes nothing. An
AXFR response or fallback is rejected without changing the zone. The input must
start at the zone's current SOA serial, each delta's deleted and added apex SOAs
must agree with its declared start/end, and every adjacent serial boundary must
chain. Record names/classes must agree with the staged zone. The current
proposal also treats an absent requested deletion as divergence, but that API
policy must be frozen and fairness-audited before artifacts are created.

Success must be equivalent to loading the final complete record set through the
existing `Zone` surface, including wildcard queries, RRsets and signatures,
SOA/NS accessors, and iteration. Failure must preserve the exact pre-call
observable state. The transfer and its lists remain caller-owned. The contract
does not mandate copy-on-write, map replacement, a particular exception type
beyond repository conventions, callback-handler support, or AXFR fallback
application.

## Trajectory-informed discriminator ledger

| Repository/trajectory signal | Plausible shortcut | Fair public invariant | Black-box oracle |
|---|---|---|---|
| IXFR can contain multiple deltas | Apply only the final pair | Every ordered delta contributes to the final zone | Two deltas whose first adds a record retained by the second |
| SOA serials are unsigned cyclic values | Use ordinary numeric ordering | Start/end and continuity use RFC 1982 semantics | A valid chain crossing `0xFFFFFFFF` |
| Old and new SOAs frame each delta | Trust mutable `start`/`end` fields alone | Framing SOAs and declared serials agree at the apex | Mismatched or non-apex boundary SOA rolls back |
| Deletes are concrete DNS records | Ignore a missing delete | If strict divergence detection is retained in the public contract, every requested deletion is validated against staged state | One absent middle-delta record leaves the zone unchanged |
| Existing public mutations lock per call | Loop over `removeRecord`/`addRecord` | One repository-supported, read-locked observation never sees an intermediate record set | A concurrent exact lookup of one large RRset sees only the old or final cardinality |
| `Zone` caches apex and wildcard state | Swap data but leave derived fields stale | Accessors and wildcard queries match the final record set | Add a wildcard and replace SOA/NS, then query all observable surfaces |
| RRSIGs join covered-type RRsets | Treat signatures as unrelated ordinary types | Covered data and signatures add/delete consistently | Change a signed RRset and compare iteration/find results |
| Transfer lists are exposed to callers | Consume or rewrite the lists in place | Input deltas and records are unchanged | Snapshot transfer response before and after apply |
| AXFR fallback is a distinct response mode | Treat `getIXFR()==null` as an empty update | Fallback cannot silently leave a stale secondary current | AXFR fallback rejects and preserves state |
| Zone validity is established by `validate()` | Publish then discover missing apex data | Final SOA/NS invariants hold before publication | Remove last NS or produce invalid SOA count and verify rollback |

The reader oracle must respect `Zone`'s documented weakly consistent iterators.
Atomicity can prohibit an individual locked lookup from observing a partially
mutated RRset/map, but it cannot require an iterator created before publication
to become a coherent snapshot or require two separate read calls to observe the
same generation while a writer may legally commit between them. The disposable
concurrency probe therefore tests one exact lookup of one 1,500-record RRset.

## Disposable convergence trial - 2026-08-11

Two implementation trials started from independent clean clones of the frozen
pin. They used the qualified offline image, cache, arbitrary UID, and loopback
setup from `ENVIRONMENT.md`. Neither trial changed the Olympus workspace or
created a submission artifact.

| Trial | Independent staging representation | Production result | Focused result | Complete suite |
|---|---|---|---|---|
| A | Complete ordered record list, replayed into a validated candidate `Zone` | One production file, 110 additions | 5/5 passed: two-delta state/derived fields/input ownership, RFC 1982 wrap, rollback, transfer modes, and reader atomicity | 1,744 tests, 0 failures/errors, 29 skips |
| B | Canonical `TreeMap<Record, Record>`, replayed into a validated candidate `Zone` | One production file, 114 additions | 3/3 passed: multi-delta state/derived fields/input ownership, wrap/rollback, and reader atomicity | 1,742 tests, 0 failures/errors, 29 skips |

Both patches passed `git diff --check` and the repository's Spotless check.
They converged on validate/stage/publish under the existing zone write lock,
but not on a private container representation. Their complete-suite totals
include their disposable focused tests; the pristine total remains 1,739.

A third clean clone implemented the plausible shortcut: run the transfer and
loop through `removeRecord`/`addRecord`, taking the existing lock once per
record. That production mutant was only 22 additions. The same single-lookup
atomicity probe failed on all four Surefire attempts, exposing intermediate
RRset cardinalities of 1,480, 1,460, 1,482, and 1,436 instead of 1,500. The
probe therefore separates atomic publication from the cheapest in-place loop
without relying on weak iterators or correlating separate read calls.

### Fairness constraints for any escalation

- Do not require snapshot semantics from `Zone.iterator()` or require two
  separate reads to remain in one generation across a legal commit.
- Do not prescribe the staged container, wholesale map replacement, or a
  particular exception class beyond the public contract and repository
  conventions.
- Strict failure for a missing delete and rejection rather than application of
  an AXFR fallback are explicit API policies, not consequences forced by the
  current mutation methods. They must remain plainly stated and must survive
  the exact-version fairness audit; rollback can instead be exercised with an
  indisputably malformed serial/zone result if strict delete handling is
  removed.
- Do not make private `Delta` construction part of the participant contract.
  Final tests should use a repository-supported fixture or a wire-level IXFR
  response for parser/application integration where malformed boundaries are
  relevant.
- Do not invent alternate-class coverage: the current `Zone` surface is
  effectively IN-class. Wildcard addition is observable; merely clearing a
  stale `hasWild` optimization is not independently observable.

## Cheapest-solution audit and verdict

The cheapest correct architecture stages a complete candidate state, applies
the chain there, validates it, then publishes all base and derived state under
one write lock. That is coherent, but it must still reconcile SOA framing,
exact deletion semantics, RRset/RRSIG behavior, wildcard/cache derivation,
serial wraparound, transfer modes, and reader atomicity. A direct loop over the
existing public mutation methods is observably insufficient.

Candidate verdict at trial time: **8/10, survived and recommended for
escalation**. The
repository and black-box oracle are excellent, two legal implementations pass
the full regression suite, and the reader probe kills the direct-loop shortcut.
The measured solution is compact at 110-114 production additions and converges
on staged publication, so this remains an 8 rather than a 9.

The candidate was subsequently promoted to
`problems/dnsjava-atomic-ixfr-apply`. That exact package now contains the prompt,
17-case feature suite, reference patch, evaluator, and passing environment,
gap, fairness, and false-positive gates. Calibration remains 0/10. Statements
above about absent artifacts describe the candidate-stage checkpoint only. The
user later reported that the task was rejected because the feature had already
been implemented; that terminal outcome supersedes the local novelty verdict.
