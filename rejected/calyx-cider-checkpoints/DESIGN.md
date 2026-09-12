# DESIGN - Cider host-backed primitive checkpoint experiment

Status: `closed; redesign rejected`.

Repository: `calyxir/calyx` at
`264c618e3db8bab3d110a0c03ff44df3611e8990`.

## Public contract and repository evidence

This document evaluates a materially different seed from the rejected portable
Cider checkpoint task: allow a host-backed stateful primitive to consume values
that cannot be reread from its provider, and preserve its behavior across a
checkpoint restored into a fresh interpreter.

The seed is not approved as a problem contract. Cider currently has no public
host-primitive registration seam. `CellPrototype::Unknown` preserves the name
and bindings of an unsupported Calyx primitive, but `build_primitive` ends in a
`todo!` for that variant. `Primitive` exposes cycle/comb evaluation, cloning,
and output-only `SerializeState`; it has neither a portable restoration hook
nor a factory/provider context. The environment's `pinned_ports` are intended
for external tools, but represent forced values rather than a stateful
host-backed primitive.

Any viable redesign would first need repository-natural public behavior for:

- registering or resolving an otherwise unknown primitive;
- supplying a fresh instance with a host provider;
- saving and restoring provider-visible live state without re-consuming
  irreversible input;
- rejecting incompatible primitive kinds or schemas atomically; and
- defining whether a checkpoint may retain the transcript of values already
  consumed.

That last point is the discriminator question. If transcripts are permitted,
nondeterminism changes the replay checkpoint from a cycle counter into an event
log but does not eliminate replay.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`, the Calyx
audit/map/prototype records, and problem records for checkpoint, restore,
replay, coupled state, staged mutation, provenance, and rollback. Relevant
compact records were read for Statig and moov ACH. Raw Statig fourth-round
trajectories and the archived moov runs 5, 10, 12, and 13 had already been
inspected; their evaluator results and implementation progression were
rechecked for this redesign. There are no Calyx solver trajectories.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | Statig `agent-runs4/Nova_Nova_4` | Passed its complete focused and baseline suites | Carried mutation-stable provenance through the operation using private coordination state, while preserving public API shape and both execution modes. |
| Near-pass | moov ACH `actual_trajectories/run_nova_10` | 118/120 focused; baseline passed | Implemented the coupled correction pipeline but derived/restored one control field from the wrong boundary, demonstrating that restoring visible state alone can miss provider/control provenance. |
| Broad failure | moov ACH `actual_trajectories/run_nova_12` | 100/120 focused; baseline passed | Mutated coupled offsets during tentative work and restored only the obvious target; later operations observed contaminated state. |

These trajectories supply only generalized evidence about coupled state and
commit timing. They do not justify a Calyx host-provider API. Repository
evidence remains controlling.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| The original Calyx probe replaced runtime serialization with deterministic replay. | Reconstruct current state from compact historical inputs instead of saving live state. | Restore must not ask the live provider for values that were consumed before the checkpoint. | A one-way provider counts reads and rejects any attempt to reread its consumed prefix; restored continuation must produce the uninterrupted suffix. | Provider consumption across restore | Observes provider calls and outputs, not checkpoint representation. |
| A transcript can supply prior nondeterministic values during replay. | Log the nondeterministic history and replay against the log before reattaching the live provider. | Unresolved: no current repository contract forbids retaining consumed values or doing reconstruction work. | Prototype whether transcript replay satisfies the one-way-provider oracle without duplicate live reads. | Discriminator viability | Explicitly preserves a legitimate alternate implementation rather than hiding it. |
| Moov near/broad failures restored only visible targets or derived state from the wrong boundary. | Snapshot the obvious primitive output but omit provider cursor/schema state. | Failed restore must leave both simulator and provider coordination unchanged; successful restore must continue at the exact provider position. | Corrupt and provider-mismatch attempts followed by a valid continuation, observing reads and outputs. | Validation/commit atomicity | Multiple staging, validation, snapshot, or log architectures can pass. |

## Clause-to-test coverage

No hidden tests are approved. The disposable experiment asks:

| Candidate public requirement | Experimental observable probe | Base behavior | Prototype target | Fairness evidence |
|---|---|---|---|---|
| Do not reread consumed host input | Count live provider reads across save/restore | No host primitive seam | No duplicate reads | Natural for a consumptive provider |
| Preserve continuation values | Compare uninterrupted and restored suffix | Unsupported | Exact equality | Public stream behavior |
| Reject mismatched provider state atomically | Attempt restore against a different provider identity | Unsupported | Error with unchanged cursor | Existing Cider checkpoint compatibility hypothesis |
| Defeat transcript replay | Attempt a transcript-backed implementation | N/A | Must fail for a valid public reason | This is the redesign's stop gate |

## Environment and harness preflight

- The pinned official-image offline Cider build and focused suites passed as
  recorded in `ENVIRONMENT.md`.
- The experiment uses only the pinned Rust toolchain and standard library.
- There is no current host-primitive registry, so integration would touch
  flattening, primitive construction, environment setup, and state hooks.
- A consumptive provider is deliberately nondeterministic from Cider's point of
  view, but a recorded transcript is deterministic evidence after observation.

## Design verdict

Rejected. The disposable experiment showed that transcript replay satisfies
the strongest natural one-way-provider oracle: the live provider was never
asked to reproduce consumed values, continuation matched uninterrupted
execution, and mismatched-provider restoration performed no reads.

The provider supplied seven values. Three were consumed before the checkpoint
and stored in its transcript. Restore reconstructed the machine from those
three observations, attached the already-advanced provider, and read the
remaining four values exactly once. The final provider read count was seven,
not ten, and final state matched uninterrupted execution.

The redesign therefore does not produce a discriminator. It merely changes the
replay record from a cycle count to an input transcript. Forbidding transcripts,
bounding history, or requiring restore work independent of execution length
would add a new policy absent from Cider. No tests or public prompt should be
authored for this redesign.
