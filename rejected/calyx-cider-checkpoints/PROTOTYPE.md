# Disposable scope prototype

## Outcome

The 2026-07-25 prototype rejects the checkpoint seed at the
scope/discriminator gate. Cider's deterministic stepping admits a small,
legitimate replay checkpoint that satisfies the proposed public behavior
without serializing the intended coupled runtime state.

The disposable implementation was an untracked Rust example at
`cider/examples/replay_checkpoint_probe.rs` in the pinned checkout. It measured
190 lines, 466 words, and 5,814 bytes and was removed after the run.

## Pinned environment

- Repository: `calyxir/calyx`
- Revision: `264c618e3db8bab3d110a0c03ff44df3611e8990`
- Image: `rust:1.90-bookworm`
- Image digest:
  `sha256:3914072ca0c3b8aad871db9169a651ccfce30cf58303e5d6f2db16d1d8a7e58f`
- Network during the prototype run: disabled

The official-image preflight had already passed the focused Cider build, all 50
Cider unit tests, three passing doctests with one ignored, and a six-case
high-level declarative `runt` slice. Detailed timings and cache sizes are in
`ENVIRONMENT.md`.

## Prototype architecture

The checkpoint used CBOR to encode:

1. a format version;
2. an FNV fingerprint of the original Calyx program bytes;
3. the original input-data bytes; and
4. the number of completed interpreter cycles.

Restore validated and decoded the payload, checked the program fingerprint,
created a separate interpreter from a fresh parse and the recorded initial
data, and replayed exactly the recorded cycle count. Only after successful
replay did it replace the destination simulator. Malformed data, a version
mismatch, a different program, or replay failure therefore left the
destination unchanged.

The prototype compared both `print_pc` output and a serialized dump of all
public memory/register state. It compared these at the checkpoint boundary and
after every subsequent step until completion against an uninterrupted
interpreter.

## Cases and results

The offline command ran the example against:

- `tests/correctness/ref-cells/dot-product-ref.futil`, using binary input
  produced by the repository's data converter. The checkpoint was taken after
  cycle 7, was 550 bytes, and the run observed unequal progress in parallel
  control. The full boundary and continuation comparison passed.
- `tests/correctness/pipelined-mac.futil`. The checkpoint was taken after cycle
  7, was 566 bytes, and the run observed unequal progress in nested parallel
  and pipelined control. The full boundary and continuation comparison passed.

The combined offline prototype run completed in 1.62 seconds.

Collectively the cases cover a completed-cycle save boundary, a separately
created interpreter, nested sequential control, genuinely overlapping
parallel branches at different progress points, an invoked component with
reference bindings, memory, and a stateful pipelined arithmetic primitive.
Repeated serialization at the same boundary was deterministic. Corrupt and
program-mismatch restores were rejected without destination mutation.

## Decisive discriminator finding

The intended difficulty was serializing and rebuilding Cider's active control
position, per-thread state, reference bindings, committed values, and private
primitive pipelines across a fresh parse. The replay implementation produces
the same public checkpoint/restore behavior while depending on none of those
representations.

A black-box oracle over subsequent cycle-level debugger state and final public
outputs cannot reject replay: replay reconstructs precisely that history.
Making wall-clock restore speed, checkpoint size, or direct runtime-state
serialization mandatory would materially change the task and privilege a
private implementation rather than a repository-supported semantic boundary.
The public contract therefore does not support the intended discriminator or
honest scope.

The example was deleted after recording these results. No prototype code was
promoted into a solution or test artifact.

## Nondeterministic provider redesign experiment

On 2026-07-25 a second disposable example tested whether a one-way host
provider would defeat replay. The 144-line, 320-word Rust program modeled a
provider whose consumed values were permanently removed and whose live reads
were counted. A checkpoint stored the provider identity and the three values
observed before saving.

Restore replayed those three values from the checkpoint transcript, never from
the live provider, and then attached the already-advanced provider for the four
unread values. It completed with the same state as uninterrupted execution,
with seven total live reads for seven inputs. A provider-identity mismatch was
rejected without performing a read.

The offline command used `rust:1.90-bookworm` with
`RUSTUP_TOOLCHAIN=1.90.0`, `--network none`, and Cargo `--offline`. It compiled
and ran in 6.84 seconds and printed:

```text
transcript replay passed: cycles=7, live_reads=7, transcript_values=3
```

The initial command omitted the exact installed-toolchain selector, causing
rustup to attempt a blocked channel metadata lookup. No dependency was missing
and no network-enabled retry was used.

This experiment rejects the nondeterministic-provider redesign. Nondeterminism
does not defeat replay when prior observations may be retained; it only changes
the replay checkpoint from a cycle counter to an event transcript. The
disposable example was removed.
