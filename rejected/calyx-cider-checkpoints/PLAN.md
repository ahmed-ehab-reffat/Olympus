# PLAN - portable cycle-exact Cider checkpoints

Status: **rejected at the scope/discriminator gate on 2026-07-25**. Eligibility,
the minimal official-image offline preflight, upstream audit, repository
mapping, and trajectory review passed. The disposable prototype then showed
that the public behavioral contract can be satisfied by recording the original
inputs and completed-cycle count and replaying deterministically into a fresh
interpreter. Black-box tests cannot distinguish that small legitimate solution
from serialization of Cider's coupled runtime state. Do not create `DESIGN.md`,
`meta.md`, `test.patch`, or a reference solution for this seed.

## 1. Task identity

| Field | Current handoff |
|---|---|
| Repository | `calyxir/calyx` |
| Language | Rust production changes; supported Python test tooling may be used |
| Task type | feature request |
| Candidate commit | `264c618e3db8bab3d110a0c03ff44df3611e8990` |
| License | MIT (reverify at the pinned commit) |
| Work namespace | `work/calyx-cider-checkpoints/` |
| Working title | Portable cycle-exact Cider checkpoints |
| Candidate rating | Rejected; formerly conditional 8/10 |

The seed is to let Cider checkpoint an in-progress interpretation and restore
that checkpoint into a freshly loaded matching Calyx program. Continuing from
the restored interpreter should produce the same subsequent cycle-level
behavior and final public output as uninterrupted execution.

The likely state boundary includes the active control position, logical time
for parallel control, reference bindings, observable port values, and stateful
primitive data. These are hypotheses for repository investigation, not an
approved public contract. The agent must determine the minimum coherent state
from Cider's actual architecture and public debugger/interpreter behavior.

Do not broaden the task into process checkpointing, compiler-pass state,
waveform persistence, distributed execution, arbitrary program migration, or a
new general serialization framework.

## 2. Mandatory stop gates

Run the gates in this order. Record commands, dates, exact revisions, and
results. A failure stops the candidate; update `candidates/CANDIDATES.md` with
the rejection instead of weakening the gate or quietly changing the task.

### 2.1 Current eligibility

Reverify from primary sources:

- the public repository and default branch;
- at least 500 stars;
- a default-branch commit within the last twelve months;
- MIT or another allowed permissive license;
- Rust as the primary implementation language and as the language of the
  expected production patch;
- every compiler, interpreter, runtime, native library, and external tool used
  by the focused and baseline Cider tests; and
- committed Cargo and Python locks at the pinned revision.

Freeze one green full commit. Do not use the abbreviated candidate SHA in any
submission artifact.

### 2.2 Minimal official-image and offline preflight

Before creating further problem artifacts:

1. Create a pristine checkout in `work/calyx-cider-checkpoints/upstream`.
2. Identify the smallest official Rust base that can build Cider and its
   directly required Calyx crates.
3. Warm only dependencies declared by the pinned repository.
4. Disable networking.
5. Build the focused Cider target and run its unit tests plus the smallest
   representative declarative `runt` slice.
6. Confirm that the slice exercises high-level control, not only fully lowered
   programs.
7. Record wall time, disk use, required Python tooling, generated fixtures, and
   any external HDL/compiler dependency.

The full project image is known to pull in heavyweight FPGA, HDL, and compiler
tools. Do not make those tools part of the challenge unless the focused public
contract genuinely requires them. If Cider cannot be built and tested
reproducibly offline without that environment, reject the candidate.

### 2.3 Exhaustive upstream and research audit

Create `UPSTREAM_AUDIT.md`. Search all open, closed, and merged issues and pull
requests; Discussions; releases; changelogs; every fetched branch and tag; Git
history; code and tests; Calyx documentation; Cider papers, theses, talks, and
research artifacts; and referenced forks.

Search titles and bodies using combinations of:

- `Cider`, `interpreter`, `debugger`, `state`;
- `checkpoint`, `snapshot`, `save state`, `load state`;
- `resume`, `restore`, `restart`, `replay`, `rewind`;
- `serialize`, `deserialize`, `persistence`, `portable`;
- `program counter`, `control point`, `continuation`;
- `parallel`, `par`, `thread`, `clock`, `logical time`;
- `reference cell`, `ref binding`, `port value`;
- `primitive state`, `register`, `memory`, `state_share`;
- `breakpoint`, `watchpoint`, `step`, `where`; and
- names of the concrete Cider types found during the repository map.

Preliminary web and candidate-registry searches found Cider debugger commands
for stepping and displaying the active control tree, and output support for
memories/registers, but no exact checkpoint/resume task. That is only a search
lead. It is not an exhaustive novelty result.

Stop if prior art already implements, specifies, rejects, or conspicuously
invites the same central operation. Do not rescue an overlapping task by
renaming the format or adding incremental fields.

### 2.4 Local history and archive similarity

The 2026-07-25 local search covered `problems/`, `archive/`,
`candidates/CANDIDATES.md`, and the problem indexes for Calyx, Cider,
checkpoint/resume, interpreter state, and cycle-exact behavior.

Results:

- no earlier Calyx problem, Calyx solver run, or Calyx-specific trajectory was
  found;
- `veryl-lang/veryl` is deliberately held outside the same hardware
  interpreter neighborhood;
- Statig trajectories contain mutable execution-boundary failures;
- Moov trajectories contain incomplete restoration of coupled state; and
- 3D Tiles contains byte-exact snapshots, but its transactional publication
  task is not a model for Cider's semantics.

These analogies may suggest questions, never Calyx requirements. Before hidden
test design, read the relevant compact records and representative raw
trajectories required by `PROBLEM_DESIGN.md`, then record the evidence and
discriminator ledger in this problem's `DESIGN.md`. If the platform exposes a
private submission archive, search checkpointed interpreter/debugger tasks
before proceeding.

## 3. Repository map to produce

Create `REPO_MAP.md` after the checkout. At minimum, locate and explain:

- Cider's executable and library entry points;
- the interpreter construction and program-loading path;
- the step/run loop and definition of one logical cycle;
- the runtime representation of `seq`, `par`, `if`, `while`, `invoke`, and
  group enables;
- active-control or program-counter state used by debugger `where`;
- per-thread or per-control-node logical clocks;
- component instances and reference-cell bindings;
- the environment used to calculate and commit port values;
- stateful primitives, registers, memories, and external data;
- combinational or derived values that should be recomputed rather than stored;
- source identifiers and stable identities available after a fresh parse;
- existing data serialization and `cider-data-converter`;
- debugger stepping, breakpoints, watchpoints, and output commands;
- unit, integration, snapshot, and declarative `runt` harnesses; and
- all feature flags or crates needed for a focused offline build.

For each state-bearing type, record ownership, lifetime/arena dependencies,
stable program identity, mutation timing within a cycle, and whether it can be
reconstructed from the program plus a smaller checkpoint.

## 4. Feasibility questions

Answer these before fixing an API or format:

1. Is there a public or maintainer-natural seam for saving and restoring an
   interpreter, or would the task require exposing private architecture?
2. Can a checkpoint be restored into a separately parsed but structurally
   matching program without serializing arena addresses or Rust-specific
   discriminants?
3. What stable identity maps components, cells, groups, control nodes,
   references, ports, and primitives across the fresh load?
4. At what points in the evaluation/commit cycle is state self-consistent?
5. Does `par` have branch-local clocks or scheduling state that a single global
   cycle counter cannot recover?
6. Which port values are committed state, and which must be recalculated after
   restore?
7. How are reference cells rebound without accidentally targeting a similarly
   named cell in another component instance?
8. Which stateful primitives can be represented portably and deterministically?
9. How should a checkpoint reject a different program, changed initial data,
   incompatible schema version, truncation, or malformed contents without
   partially mutating the destination interpreter?
10. Can a legitimate implementation naturally clear the platform's scope and
    long-horizon criteria without padding?

If fresh-load identity cannot be made public, deterministic, and
repository-native, reject or materially redesign the seed before tests.

## 5. Disposable scope prototype

After all prior gates pass, create an isolated disposable prototype. It may
choose a temporary internal representation, but it must demonstrate:

- save after at least one completed cycle;
- load into a separately created interpreter for the same program;
- continue to the same final public memory/register output as uninterrupted
  execution;
- one nested sequential-control case;
- one genuinely overlapping `par` case in which branches are at different
  progress points;
- one invoked component with reference bindings;
- one stateful primitive beyond the simplest scalar register;
- deterministic checkpoint bytes or a documented canonical equivalence;
- clean rejection of a non-matching program and malformed input; and
- no destination-state mutation on restore failure.

Measure strict effective production lines and touched subsystems. Delete or
archive the disposable implementation after recording evidence; do not let a
prototype silently become the reference solution.

## 6. Candidate behavioral model

Only promote requirements supported by repository evidence. A coherent design
is likely to need the following observable properties:

- `run N cycles; save; fresh load; restore; run to completion` is equivalent to
  uninterrupted execution from the same program and initial data;
- equivalence includes final public outputs and subsequent cycle-by-cycle
  debugger-visible control progress;
- checkpoints carry a format/version and enough program identity to reject
  incompatible restores;
- a failed restore leaves the fresh interpreter in its pre-restore state;
- repeated serialization of the same quiescent interpreter state is stable;
- restoring does not duplicate or skip a control action; and
- state is portable across object addresses and fresh parses, not merely
  cloneable inside one process.

Do not require byte equality if the repository supports multiple legitimate
canonical encodings. Do not require one private type layout, traversal order,
hash algorithm, or serialization library. The public contract must define
observable equivalence and compatibility precisely enough for independent
implementations.

## 7. Design and test phase

Once sections 2-5 pass:

1. Read `PROBLEM_DESIGN.md` again.
2. Create `DESIGN.md` from `templates/problem/DESIGN.md`.
3. Record the trajectory evidence table and trajectory-informed discriminator
   ledger before revising or creating `test.patch`.
4. Create `UPSTREAM_AUDIT.md`, `REPO_MAP.md`, `LEVELS.md`, `ERRORS.md`,
   `SUMMARY.md`, and `verify/` as evidence becomes available.
5. Write a concise maintainer-facing `meta.md` that states public behavior,
   not private checkpoint contents or hidden-test fixtures.
6. Build tests through public entry points wherever possible.
7. Preserve all baseline interpreter/compiler behavior and the focused offline
   feature composition.

Candidate discriminator families should span distinct boundaries:

- sequential control position;
- unbalanced progress among parallel branches;
- nested invocation and reference rebinding;
- primitive/memory state versus derived port recomputation;
- fresh-parse stable identity;
- checkpoint compatibility and corruption handling; and
- failure atomicity.

This is a starting taxonomy, not permission to add one test per row. Each final
discriminator must trace to a public requirement, a black-box oracle, a
distinct failure family, and trajectory or repository evidence.

## 8. Mandatory false-positive audit

Before calibration, follow the false-positive gate in `AGENTS.md`, using
`problems/statig-local-transitions/false_postive trials.md` as the worked
reference:

1. Map every participant-facing requirement to its strongest test.
2. Construct plausible incorrect checkpoint implementations from the actual
   Cider architecture and reviewed solver shortcuts.
3. Find mutants that compile and pass the focused suite.
4. Run meaningful survivors through the complete pre-existing suite.
5. Prototype black-box probes that pass the reference and isolate actionable
   survivors.
6. Replay representative solver patches when available.
7. Reject artificial mutants and redundant symmetry cases.
8. Record survivors, rejected trials, mutation isolation, complete-suite
   results, and immutable artifact hashes.

Changing any prompt, test, reference behavior, or submission artifact creates a
new immutable version. Repeat all required checks and restart calibration at
0/10.

## 9. Verification and calibration

Build one reproducible verifier that checks:

- patch applicability from the exact pinned base;
- focused base failures;
- reference focused passes;
- complete baseline passes before and after the reference;
- the minimal offline feature/build matrix;
- formatting and relevant linting;
- mutation/false-positive gates;
- artifact integrity; and
- absence of leaked fixtures, solution details, absolute paths, and network
  dependencies.

Then read `CALIBRATION_STRATEGY.md` before advising solver runs. Run one Nova
and one Orion local preflight against the exact immutable version, save their
trajectories under `estimate_trajectories/`, and harden before upload if both
solve cleanly. Platform calibration starts at 0/10 and follows the recorded
two-run batch protocol without mixing problem versions.

## 10. Handoff completion criteria

The next agent should leave one of two evidence-backed outcomes.

### Proceed

- eligibility is current and pinned;
- the minimal official-image offline lane passes;
- exhaustive upstream, research, local, and archive audits pass;
- the repository map identifies a portable restore boundary;
- the disposable prototype demonstrates cycle-exact fresh-load continuation;
- honest scope is sufficient;
- `DESIGN.md` records the required trajectory gate; and
- the public contract admits multiple correct internal implementations.

### Reject

- record the decisive failed gate in this plan and
  `candidates/CANDIDATES.md`;
- preserve commands, logs, links, and any disposable measurements;
- do not author hidden tests or inflate/rescope the task to save the rating; and
- update `problems/README.md` with the final state if this folder becomes a
  durable rejection record.

Do not commit active work. Olympus commits only at verified cleanup or archival
checkpoints.

## 11. Final outcome — reject

The candidate reached the disposable prototype and failed there. A 190-line,
466-word Rust example implemented a portable checkpoint as:

- a schema version;
- a deterministic fingerprint of the original program;
- the original input-data bytes; and
- the number of completed cycles.

Restore parsed the same program into a new interpreter, replayed the recorded
number of cycles from the original inputs, and swapped the reconstructed
interpreter into the destination only after all validation and replay
succeeded. This naturally provided fresh-parse portability, deterministic
bytes, mismatch and malformed-input rejection, and failure atomicity without
serializing Cider's program counter, parallel-thread maps, reference bindings,
ports, memories, registers, or primitive pipeline internals.

The probe matched debugger-visible control state and all serialized public
memory/register output at the checkpoint boundary and after every subsequent
cycle on both `dot-product-ref.futil` and `pipelined-mac.futil`. Together these
exercise nested sequential and parallel control, unequal parallel progress,
invocation with reference cells, memories, and a pipelined multiplier. See
`PROTOTYPE.md` for the commands and measurements.

Forbidding replay would impose a private implementation strategy or a
performance constraint unsupported by the seed's observable semantics.
Permitting it leaves an honest solution materially smaller and less
architecturally coupled than the intended task. The candidate is therefore
rejected rather than padded or quietly redesigned. The disposable example was
removed, and no hidden tests or submission artifacts were authored.

### Follow-up nondeterministic-provider redesign

A 2026-07-25 follow-up tested a consumptive host provider whose values cannot
be reread. It did not rescue the task. A 144-line checkpoint implementation
stored the three values observed before saving, replayed that transcript
without consulting the live provider, and then attached the already-advanced
provider to consume the remaining four values. Final state matched
uninterrupted execution and the provider observed exactly seven reads for seven
inputs. Provider mismatch was rejected without a read.

Nondeterminism therefore changes the replay artifact from a cycle count to an
event log but does not force serialization of live Cider state. The redesign is
also rejected. See `DESIGN.md` and the final section of `PROTOTYPE.md`.
