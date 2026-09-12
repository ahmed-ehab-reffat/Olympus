# DESIGN.md — makerjs-box-joinery

Repo: microsoft/maker.js (TypeScript, Apache-2.0, 2021 stars)
BASE_COMMIT: d25a182a72fbfbcb88ab01bfc039eb006da9c58d (2026-06-27)

## 1. Title

Add finger joint generation for laser cut box faces

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK § Pattern 12) — a new capability whose difficulty is a
  subtle arithmetic/ordering kernel reused by every surface, not breadth of independent handlers.
- Pass rate target: <= 40% sprint cap; design target **1/10 (10%)**, the corpus mode.
- Best agent: Mixed.
- Dominant verdict: MISSED_REQUIREMENT (finger parity + kerf direction), then INTEGRATION_ERROR
  (corner resolution between two jointed edges).

## 3. Public API surface

New namespace `MakerJs.joinery` in `src/core/joinery.ts`:

- `joinery.IFinger` — `{ start: number; end: number; tab: boolean }`, one span along an edge.
- `joinery.IFingerOptions` — `{ fingerWidth: number; thickness: number; kerf?: number; startWithTab?: boolean }`.
- `joinery.fingerCount(length, fingerWidth) -> number` — odd finger count for an edge.
- `joinery.fingers(length, options) -> IFinger[]` — the kerf-compensated partition of one edge.
- `joinery.complement(fingers, kerf) -> IFinger[]` — the mating partition; applying it twice is the identity.
- `joinery.profile(fingers, thickness) -> IPoint[]` — staircase points along a local edge.
- `joinery.slots(fingers, thickness) -> IModel` — a closed rectangle per slot, named `Slot1` upward.
- `joinery.mortises(fingers, thickness, kerf) -> IModel` — a pocket per tab, named `Mortise1` upward.
- `joinery.mates(a, b, kerf) -> boolean` — true when two partitions interlock once the kerf comes off.
- `joinery.report(model) -> IJointReport` — `{ faces, tabs, slots, cutLength }`.
- `models.JointedRectangle(width, height, options)` — rectangle whose edges carry joints; exposes `.joints`.
- `models.FingerBox(width, depth, height, options)` — six (or five) mating faces plus divider panels; exposes `.seams`.

## 4. Canonical output form

- `fingers` are returned in increasing `start` order, spanning `[0, length]` with no gaps.
- Finger count is ODD, minimum 3; when two odd integers are equally near `length / fingerWidth`, the
  larger is used.
- Fingers alternate; finger 0 is a tab iff `startWithTab` (default true).
- Kerf moves every INTERIOR boundary by half the kerf toward the neighbouring slot. The two outer
  boundaries never move. So interior tabs are widened by a full kerf, end tabs by half.
- `profile` walks from the edge start to the edge end; slots are displaced by `thickness` on +y.
- Rectangle paths are named `Edge<n>` in counterclockwise traversal order starting at the bottom edge.
- A slot at a corner swallows that corner; where both edges are slotted the outline turns at the point
  set in by the thickness from each. Corner resolution dedupes structurally, so no zero-length path arises.
- Invalid input (`fingerWidth <= 0`, `thickness <= 0`, `length <= 0`, a negative kerf, a kerf as wide as
  a finger, a kerf as thick as the material, a divider outside the box) is rejected with a message
  containing `joinery:`. Only that substring is pinned, so an agent chooses its own wording.

## 5. Blind-spot pre-empts

- Iteration termination / parity: "divided into an odd number of equal fingers" (states the parity rule).
- Compound order preservation: "counterclockwise from the origin" (states traversal).
- Rule resolution: kerf sentence names the direction (toward the neighbouring slot) and the exception
  (outer boundaries never move).
- Unstated inverse: the mating rule is stated for BOTH sides (which face starts with a tab).

## 6. Description draft

See meta.md. Shipped at 459 words, over the 200-word guidance and under the 500-word hard cap;
the overage and its justification are logged in feedback.md.

## 7. File footprint

| Action | Path | Raw | Human-effective | Reason |
| --- | --- | --- | --- | --- |
| NEW | packages/maker.js/src/core/joinery.ts | 371 | 254 | the finger kernel, mortises, mates, report |
| NEW | packages/maker.js/src/models/FingerBox.ts | 193 | 132 | six faces, polarity plan, dividers |
| NEW | packages/maker.js/src/models/JointedRectangle.ts | 150 | 102 | per-edge assembly + corner resolution |
| MODIFY | packages/maker.js/target/tsconfig.json | 3 | 3 | register new files (dist build) |
| MODIFY | packages/maker.js/tsconfig.json | 3 | 3 | register new files (debug build) |

Measured: 720 raw, **494 human-effective**, 5 files.


## 8. Solution outline — helpers

- `fingerCount(length, fingerWidth)` <- "odd number of equal fingers" requirement
- `fingers(length, options)` <- partition + kerf requirement
- `complement(fingers)` <- mating requirement
- `profile(fingers, thickness)` <- staircase requirement
- `mates(a, b)` <- interlock requirement
- `report(model)` <- summary requirement
- `edgePoints(...)` (private) <- maps a local profile onto one rectangle edge with orientation

## 9. Test file outline

Path: `packages/maker.js/test/joinery_816324.js` (mocha + assert, matching the repo's existing
plain-JS tests; the hex suffix keeps the filename unguessable). 142 tests shipped.

Block 1 — require makerjs from dist.
Block 2 — builder helpers (fingers for a given length/width, a standard box).
Block 3 — assertion helpers (`near`, `nearPoints`, `pocketExtents`, `expectThrows`).
Block 4 — buckets: finger count / kerf / profile / rectangle assembly / box polarity / mating /
mortises / dividers / report / edge cases (tiny edge, minimum count, open box, invalid input).

## 10. Forced signatures

All new public signatures are pinned in meta.md (avoids the compile-time signature coin-flip
anti-pattern). Tests are plain JavaScript, so a wrong signature fails at runtime per test rather
than wiping the whole binary.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Mutation kills |
| --- | --- | --- | --- | --- |
| 1 | Finger count must be ODD, minimum 3, ties round up | `Math.round(length/width)` is the obvious line and yields even counts | "an odd number of equal fingers" plus the tie rule | 4 / 2 / 4 |
| 2 | Kerf moves interior boundaries toward the neighbouring SLOT; outer boundaries never move | uniform widening is the obvious reading, and end fingers take only half a kerf | the kerf sentence names direction and the exception | 11 / 11 |
| 3 | Fingers are equal and span the edge exactly | laying out fingers of the nominal width leaves a remainder at the end | "odd number of EQUAL fingers" | 2 |
| 4 | Mortises are the mate's pockets, NARROWED by the kerf, while the tabs entering them are WIDENED | the same kerf rule points opposite ways on the two parts | the mortises sentence | 7 / 2 |
| 5 | A slot at a corner swallows it; two slotted edges meet at the doubly inset point | emitting both profiles makes the outline double back on itself | the corner sentence | 1 / 2 |

Traps 1 and 3 are interdependent: the count sets the width, so a parity fix changes every span.
Traps 2 and 4 are one rule seen from both sides of a joint.

**Retired during implementation:** a traversal-direction trap was predicted (mating faces walk the
shared edge in opposite directions) but it does not exist. An odd finger count makes the partition
palindromic, so reversing it is the identity. That is precisely why box joints use odd counts, and
it is a good reminder that a predicted trap is only real once a mutation kills a test.

## 12. Tier + category

- Tier: Olympus
- Category: feature-request (net-new public API)

## 13. Predicted pass rate

10-25%. Levers stacked: one interdependent kernel driving 4 surfaces (lever 1); exact structural
oracle, complementarity verified independently (lever 2); 3 misdirecting traps (lever 3); an
"obvious code is wrong" parity edge (lever 4); a de-trained niche domain, 2D CAM joinery (lever 5).

## 14. Quality gate

- [x] Repo understanding 5/5 (see feedback.md)
- [x] Existing PR check: zero PRs and zero branches touch joinery; the only prior art is a 27-line
      docs demo that clones a Dogbone into a row
- [x] Corpus scaffolding opened
- [x] Signatures pinned in meta
- [x] Not a famous portable spec (bespoke contract, not a documented file format)
- [x] Canonical output form spelled out
- [x] Feature is not pattern-followable (no similar generator in the repo)
- [x] Mutation battery: 22 mutations, 22 killed, 0 survivors
- [x] Every one of the 142 new tests fails on base, none vacuously
- [x] Vanilla `npm test` passes offline as uid 1000 (Environment Quality)

## Why this is not a duplicate

No approved or in-flight problem touches CAD/CAM, 2D geometry assembly, or joinery. The closest
approved work by mechanism is `asciimatics-diagram-renderer` (a per-cell kernel feeding a renderer);
this differs in domain, in kernel (an arithmetic partition with parity and kerf), and in the
verification surface (structural complementarity between two independently generated parts).

Predicted iteration cycles: 2
