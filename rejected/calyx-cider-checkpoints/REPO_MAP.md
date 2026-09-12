# Repository map - portable cycle-exact Cider checkpoints

Pinned source:
`264c618e3db8bab3d110a0c03ff44df3611e8990`

## Construction and public seams

`cider/src/flatten/setup.rs` is the program-loading seam.
`setup_simulation` parses a Calyx workspace, validates it, translates it into a
flat `Context`, and returns that immutable context.

`Simulator::build_simulator` in
`cider/src/flatten/structures/environment/env.rs` combines a context, optional
input data, runtime configuration, and evaluation policy. `Debugger::from_file`
uses the metadata-producing setup variant and then constructs the same runtime
machinery.

`BaseSimulator` is cloneable and intentionally separated from the waveform
wrapper. This is a maintainer-natural library seam for checkpoint methods, but
an existing clone is not a portable checkpoint.

## One logical cycle

`BaseSimulator::step` is the cycle boundary:

1. converge combinational assignments and active control;
2. perform optional transitive-read checks;
3. call `exec_cycle`/`exec_cycle_checked` on every primitive;
4. advance control nodes and `par` bookkeeping;
5. update invocation bindings, clocks, and thread state; and
6. reconverge on the next call.

`run_program_inner` calls `step` until the root `done` port is high. A
checkpoint taken after a successful `step` is self-consistent; taking one
inside convergence or primitive commit is not a supported boundary.

## Runtime state ownership

The mutable runtime boundary is `Environment<C>`:

| Field | Role | Checkpoint treatment |
|---|---|---|
| `ports` | current global port values and assignment provenance | preserve committed values needed for exact next-cycle behavior; derived combinational values may be recomputed only if proven equivalent |
| `cells` | component ledgers and boxed primitive implementations | component layout is reconstructed; stateful primitive internals need portable state hooks |
| `ref_cells`, `ref_ports` | current invocation bindings | preserve by stable instance-relative identity |
| `state_map` | centralized register/memory values and their race clocks | preserve |
| `pc` | active/paused leaves plus `par`, `with`, `repeat`, completion, and thread memoization state | preserve |
| `pinned_ports` | external forced values | preserve if checkpointing is exposed while pins are active |
| `clocks` | vector clocks and read/write metadata | preserve when race checking is enabled |
| `thread_map` | thread parent and clock identities | preserve with the program counter |
| `memory_header` | loaded external-data declarations | compatibility input; reconstruct or validate |
| logger/scratch maps | diagnostics and reusable work buffers | reconstruct |
| immutable `ctx` | flattened program | fresh-load input, never serialized as arena/object addresses |

## Control representation

`Control` in `flat_ir/control/structures.rs` represents enables, `seq`, `par`,
`if`, `while`, `repeat`, and `invoke`. `ProgramCounter` stores active leaf
`ProgramPointer`s, each containing:

- an optional thread index;
- a `ControlPoint` with component instance and control-node indices; and
- active/paused status.

It also stores:

- `par_map` child counts, finished children, and parent-thread restoration;
- `with_map` condition-group phase;
- `repeat_map` iteration counts;
- recently finished components;
- continuous assignments; and
- the thread memoizer.

A global cycle count cannot reconstruct these coupled fields.

## Parallel time and scheduling

`ThreadMap` owns parent/clock associations. `ClockMap` owns vector clocks and
read/write information. A `par` may have multiple active pointers at different
control positions even though the evaluator advances them during one logical
cycle. Evaluation policies may also pause individual pointers.

Portable restore must therefore preserve branch-local control and relevant
thread/clock state rather than recording only elapsed cycles.

## Components and reference bindings

Component instances are laid out recursively in deterministic indexed maps.
Each `ComponentLedger` has a component definition and `BaseIndices` for local
ports, cells, reference cells, and reference ports.

On `invoke`, `initialize_ref_cells` binds the invoked component's reference
cells and ports to the caller's concrete instances. `cleanup_ref_cells` clears
them after completion. A mid-invoke checkpoint must preserve these bindings;
rebinding by a bare cell name would be ambiguous across repeated component
instances.

The existing flat indices are deterministic for a byte-identical fresh parse,
but are internal. Issue #2273 and the control-tree printer demonstrate a
repository-native path identity. A final design should pair an exact program
fingerprint with path/index validation rather than expose Rust addresses.

## Ports and commit timing

`PortMap` stores `PortValue`, including assignment winner and transitive clock
information. Convergence repeatedly evaluates assignments and primitive
combinational paths. Stateful primitive `exec_cycle` methods commit once per
logical cycle.

Some port values are derived and can be recomputed after restore; others are
latched primitive outputs or participate in pipeline state. The disposable
prototype must compare the first post-restore cycle, not only final memory, to
detect an incorrect blanket clearing of ports.

## Stateful primitives

Registers and memories keep values in the centralized `MemoryMap`. Their
existing `SerializeState` hook is output-only (`serialize`/`dump_data`) and has
no restore half.

Pipelined multiply/divide, square-root, and fixed-point primitives retain
additional private state such as shift buffers, output registers, and `done`
phase inside boxed primitive objects. `clone_boxed` preserves this state only
inside one process. A complete design needs a portable, validated state
snapshot/restore hook for every supported stateful primitive; a memory-only
checkpoint is insufficient.

Combinational primitives have no durable private state and should be
reconstructed.

## Existing serialization

`cider/src/serialization/data_dump.rs` defines a versioned CBOR-oriented
external data dump with memory declarations and bit contents.
`cider-data-converter` translates it to and from JSON.

This format is suitable evidence for portable numeric encoding and schema
validation, but it represents input/final data, not active control,
references, clocks, ports, or pipelined primitive state. Reusing its concepts
is reasonable; overloading it as an execution checkpoint would conflate two
contracts.

## Debugger behavior

The debugger exposes:

- one-cycle `step`;
- bounded `step-over`;
- `continue`;
- breakpoints and watchpoints;
- `print` and `print-state`;
- `where`/`pc` for the active control tree; and
- restart while retaining debugger configuration.

Cycle-exact equivalence can be observed through repeated `step` plus `where`
and public state/output commands. Breakpoints, watchpoints, and command history
are debugger configuration, not interpreter execution state, unless the final
API explicitly checkpoints an owned debugger.

## Tests and focused build

`cider/tests/runt.toml` contains unit, primitive, control, invoke, reference
cell, parallel, debugger, and correctness suites. The smallest offline
high-level slice is `unit`; focused prototype coverage can invoke Cider
directly and avoid `fud2`, HDL simulators, and Python.

The `cider` crate depends only on Calyx core crates and ordinary Rust
dependencies in the locked workspace. The focused official-image lane needs
no feature flag. Race-clock coverage uses the existing runtime option rather
than a Cargo feature.

## Feasibility answers

1. `BaseSimulator`/`Environment` is a natural seam, though new public methods
   and internal primitive restore hooks are required.
2. Fresh parsing is feasible for an exact matching program because flat layout
   is deterministic; the checkpoint must not contain pointers.
3. Program fingerprint plus validated component/control paths or deterministic
   indices can identify runtime objects.
4. Save after a completed `step`, before the next convergence.
5. `par` requires active pointers, `par_map`, thread identities, and clocks;
   elapsed cycles alone are insufficient.
6. Preserve values that affect the next observation; recompute only proven
   combinational values.
7. Reference bindings must include the concrete component-instance path.
8. Every supported stateful primitive needs a portable schema; registers and
   memories alone are not enough.
9. Decode and validate into a temporary checkpoint object, including version,
   program/data fingerprint, lengths, indices, and primitive kinds, before
   mutating the destination.
10. The work spans public API, runtime state modeling, primitive hooks,
    compatibility validation, serialization, and cycle-level tests without
    unrelated framework work; honest scope is sufficient if the prototype
    succeeds.
