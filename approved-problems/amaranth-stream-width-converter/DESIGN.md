# DESIGN.md — amaranth-stream-width-converter

## 1. Title
Add stream-processing elements to Amaranth's standard-library streams

## 2. Shape / tier
O-Algorithm-correctness (subtle cycle-exact correctness; the obvious impl is wrong on backpressure boundaries). Olympus. Best agent: Orion/Vega. Dominant verdict: MISSED_REQUIREMENT (data loss under backpressure) / WRONG_LOGIC.

## 3. Public API (the names tests assert)
Eight `wiring.Component`s in `amaranth.lib.stream`, each with `valid`/`ready` streams:
- `WidthDownConverter(width, factor)` 1->factor split (LSB-first)
- `WidthUpConverter(width, factor)` factor->1 pack (LSB-first, hold partial)
- `Gearbox(i_width, o_width)` arbitrary bit-width repack (emit complete words)
- `SkidBuffer(shape)` registered-output elastic buffer, full throughput
- `Arbiter(shape, count)` count->1 work-conserving round-robin merge
- `Demux(shape, count)` 1->count routed by `select` (combinational)
- `Fork(shape, count)` 1->count broadcast, advance when all accept
- `Join(shape, count)` count->1 gather + concatenate (first input = LSBs)

## 4. Canonical form / invariants
Universal: no payload dropped/duplicated/reordered for ANY valid/ready sequence. Converters+gearbox: output bit-concatenation == input bit-concatenation, LSB-first. Up-converter/gearbox hold incomplete final group. Arbiter: per-input order preserved, round-robin fair. Demux: exactly the selected output; backpressure only from it. Fork: every output sees the full input sequence in order. Join: emit only when all inputs gathered.

## 5. Blind-spot pre-empts (in meta)
"a payload transfers ... only when both valid and ready are asserted"; "no payload may be dropped, duplicated, or reordered for any sequence of valid and ready, including when either peer withholds its signal for arbitrary stretches"; per-element order/hold/route/broadcast/gather sentences.

## 7. File footprint
MODIFY amaranth/lib/stream.py (+493 raw / 279 human-effective). One file, 8 distinct components. (>=250 sprint floor; >2 files not required at floor. Single-file is the natural home = amaranth.lib.stream.)

## 8/11. Traps (interdependent + misdirecting, all sim-verified discriminating)
1. FORGET to gate the shift/advance/accept on the downstream `ready` => data DROPPED under backpressure. Mutation test: 73/80 fuzz configs fail. Misdirecting: the failing test is a later output mismatch, not the handshake line.
2. Back-to-back acceptance (accept next on the last-transfer cycle) => a naive `ready = idle-only` bubbles / under-throughputs.
3. Simultaneous receive+send (converters/gearbox) => wrong buffer/level update loses/corrupts data.
4. Gearbox non-dividing widths: sub-word bit alignment across output boundaries.
5. Arbiter: not advancing the round-robin pointer => starvation; asserting ready on a non-granted input => loss.
6. Fork/Join: per-output/per-input tracking (a served output must not be re-served; advance only when ALL done) => partial-acceptance loss.

## 10. Forced constraints
Pure `amaranth.hdl` + `lib.wiring.Component`; no comb loops (i_ready may depend on external o_ready only). Demux is combinational (no clock domain) => tested combinationally.

## 13. Predicted pass rate
~10-30%. The eval concept (converters, arbiter, fork) is familiar, but the cycle-exact handshake is NOT transcribable from the spec; an agent must get 8 elements' backpressure boundaries right, each caught by adversarial fuzz vs a reference model. The obvious impl is wrong (verified). Oracle = the amaranth pure-Python simulator; fuzzed to 0 mismatches across 600+400+200+200 trials per family. Much harder to one-shot than a documented value-mapping.

## 14. Why not a duplicate / not reproduction
Greenfield: amaranth.lib.stream had NO processing elements (only the signature). Not a famous copyable algorithm: the correctness is amaranth's cycle-exact comb-vs-sync handshake semantics, not a published block spec. No such problem in the corpus.
