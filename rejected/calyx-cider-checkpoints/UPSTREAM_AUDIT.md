# Upstream audit - portable cycle-exact Cider checkpoints

Audit date: 2026-07-25

Pinned candidate: `264c618e3db8bab3d110a0c03ff44df3611e8990`

Current default-branch head at audit time:
`569a03e23f31b02adfe9dcdc918be93d7b2fbdc2`

## Decision

The audit found enabling infrastructure and adjacent state work, but no prior
implementation, specification, rejection, or invitation for portable
checkpointing of an in-progress Cider execution. The novelty gate passes.

The nearest upstream work is deliberately preserved as a design constraint:

- PR #2345 made `BaseSimulator` minimally cloneable for in-process model
  checking. It does not serialize state or restore into a fresh parse.
- PR #2507 centralized register and memory contents in the environment and
  extended primitive output serialization. It does not restore control,
  reference, port, clock, or primitive execution state.
- issue #2273 proposed path-like names for control nodes. It supports a
  repository-native stable-identity direction but does not persist execution.
- PR #2531 added paused program-counter nodes and evaluation policies.
- PR #2545 repaired parent-thread restoration and empty-`par` behavior.
- PR #2213 preserves debugger breakpoints, watchpoints, and command history
  across the existing restart command. Restart still creates a new execution
  rather than restoring an in-progress one.
- issue #1968 and the data-dump implementation cover initial/final memory data,
  not interpreter checkpoints.

These records make an in-process clone, memory-only dump, debugger-metadata
restart, or global-cycle-only checkpoint especially plausible incomplete
solutions. They do not overlap the central fresh-load continuation operation.

## Primary-source eligibility

The GitHub repository API and pinned checkout established:

| Fact | Result |
|---|---|
| Repository | public `calyxir/calyx` |
| Default branch | `main` |
| Stars | 607 |
| Current activity | default head committed 2026-07-24 |
| Candidate activity | pinned commit committed 2026-07-23 |
| License | MIT in API metadata and pinned `LICENSE` |
| Primary language | Rust |
| Rust toolchain | repository requests Rust 1.90 |
| Locks | root `Cargo.lock`, `uv.lock`, and scoped Cargo/npm locks committed |

## Issue, pull-request, discussion, and release searches

GitHub all-state searches covered titles and bodies using `Cider`,
`interpreter`, and `debugger` paired with:

- checkpoint, snapshot, save/load state, persistence, and portable;
- restore, resume, restart, replay, and rewind;
- serialize, deserialize, and serialization;
- program counter and continuation;
- parallel, `par`, thread, clock, and logical time;
- reference cells, reference bindings, and port values;
- primitive, register, memory, and `state_share`; and
- breakpoint, watchpoint, step, and `where`.

The repository issue endpoint was also swept in 100-item pages for recent
open/closed issues and pull requests, with targeted all-history searches used
for the complete keyword space because GitHub caps an unpartitioned result set
at 1,000 records. No exact task appeared. Search-engine queries scoped to the
repository's Discussions found no checkpoint/resume discussion.

Nine GitHub releases and all 16 fetched tags were inspected. The only
checkpoint wording was development-milestone language, notably PR #1868
("[Cider 2.0] Partial checkpoint"), not execution persistence.

## Branches, tags, history, and source

The full clone fetched 106 remote refs and 16 tags. Every fetched ref was
searched under current and historical `cider/`, `interp/`, and `docs/` paths.
History was searched by commit message and diff for the same persistence
vocabulary.

Notable false leads:

- `origin/add-simple-interp-state` adds an unfinished BTOR2 state parser, not
  Cider state.
- `origin/branch3-restore` restores unrelated data-conversion work after Git
  branch loss.
- `ProgramCounter::restore_fields` temporarily puts fields back after the
  evaluator uses `mem::take`; it is not an external restore seam.
- snapshot references describe golden-file testing.

No branch, tag, deleted-path remnant reachable from fetched history, or source
file implements Cider save/restore.

## Documentation and research

The following primary materials were reviewed:

- the Cider interpreter documentation;
- the Cider debugger documentation, including `step`, `continue`,
  `print-state`, and `where`;
- the Calyx language reference for `seq`, `par`, `if`, `while`, and `invoke`;
- *Stepwise Debugging for Hardware Accelerators* (ASPLOS 2023);
- Calyx tutorial and FCRC slide material;
- release notes and repository documentation.

They define cycle stepping, control-tree visibility, memory/register output,
and parallel execution, but contain no checkpoint, restore, persistence, or
fresh-parse continuation mechanism.

## Fork and private-archive boundary

Referenced public branches/forks reachable through the upstream ref set were
searched. No private submission archive is exposed in this workspace, so an
equivalent private task cannot be ruled out. This is recorded residual risk,
not represented as a completed search.

## Novelty conclusion

The proposed feature is distinct from:

- cloning a simulator in one process;
- restarting a debugger while retaining debugger configuration;
- input/output memory dumps;
- snapshot tests;
- Fud2 plan serialization; and
- compiler or waveform state.

The task may proceed only with an observable contract centered on restoring a
freshly constructed matching interpreter and continuing with the same
subsequent cycle behavior.
