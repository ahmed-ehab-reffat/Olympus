# feedback.md — makerjs-box-joinery

Repo: microsoft/maker.js · Apache-2.0 · 2021 stars · TypeScript
BASE_COMMIT: d25a182a72fbfbcb88ab01bfc039eb006da9c58d (2026-06-27)
Tier: Olympus · Category: feature-request · Shape: O-Algorithm-correctness

## Status

Built and locally validated. One alignment-check round fixed (below). No agent batch has been run
yet, so the pass rate is unmeasured.

## Attempt history

### Round 1 — alignment check FAILED on the mortise kerf wording (description only)

Interface information passed. Behaviors flagged one ERROR: meta.md said mortises are "shrunk by the
kerf on all four sides", which reads as 2 x kerf per dimension, while the tests expect
`thickness - kerf` across x and 2 x kerf less than the tab along y.

The tests were right and unchanged. The rule IS uniform: every pocket edge sits half a kerf inside
the NOMINAL boundary, in both directions. It only looks asymmetric because along the length the
natural comparison is against the drawn tab, which was itself widened by half a kerf per side, so
the gap doubles to a full kerf per side; across the thickness there is no widened counterpart, so
the gap stays half a kerf per side. Measured on the reference (thickness 3, kerf 1, nominal span
20 to 40): drawn tab 19.5 to 40.5 (21 long), pocket 20.5 to 39.5 (19 long), pocket 2 across x.
Inset per side against nominal is 0.5 in both directions, and the cut tab (20) equals the cut
pocket (20).

Fix: description only. The clause now states both measurements outright rather than a "four sides"
shorthand, and keeps the reason. meta.md went 459 -> 476 words; other prose was compressed to hold
the margin under the 500-word cap and the longest paragraph was split to stay under 150 words. No
test, solution or patch changed, so the validation matrix and mutation results below still stand.

### Round 2 — alignment check WARNING on the validation surface (description only)

Behaviors passed. Interface information raised three warnings, all fair: the tests assert the
`joinery:` substring on rejections from every function while meta named it only under `fingers`;
the individual validation cases were not enumerated; and the optional `kerf` defaults were stated
only for `fingers`.

Fix: one global rule replaces the two scattered ones, covering every rejection the suite asserts.
I enumerated all 21 `expectThrows` call sites and mapped each to a clause, which caught one my
first draft missed: `FingerBox`'s `depth` argument was not in the dimension list. The wording is
"at least as wide as a finger or as thick as the material" so it covers both the equal and the
greater cases the tests exercise.

To hold the 500-word cap I dropped the framing sentence, folded `slots`/`report` phrasing tighter,
and merged the seams and options sentences. Nothing tested was removed: "widening tabs and
narrowing slots" survives in compressed form, and the mortise-kerf rejection is now covered by the
global clause instead of its own sentence. meta.md 476 -> 489 words, 6 paragraphs, longest 119.
Again description only; patches, mutation results and the validation matrix are untouched.

### Round 3 — Test Fairness FAILED, 33 of 143 unfair (description + one API cut)

The verdict was right: the contract was bigger than the prompt stated. Five distinct causes, each
fixed at its root rather than by loosening an assertion.

| Cause | Unfair tests | Fix |
| --- | --- | --- |
| `profile` return shape never stated | 9 | meta now says it returns an array of `[x, y]` points, two per finger |
| divider pockets land in a per-panel child model | 10 | meta now states the pockets go in as a child model of each host face, named after the panel |
| `seams` element shape never stated | 3 | meta now says each seam holds a `tabbed` and a `slotted` `[face, edge]` array |
| validation scoped to "every `joinery` entry point", which excludes the two models | 7 | rescoped to "every function and model above", and the empty-list rule now names the functions it applies to |
| `faces` in `report` never defined | 1 | meta now says report counts the models that carry `joints` as faces |
| empty-partition rejections read as unstated per function | 3 | covered by the rescoped rule naming `complement`, `profile` and `mortises` |

Adding those clauses cost about fifty words against a 489-word description with an eleven-word
margin, so `joinery.slots` was cut entirely: solution, its five tests, its meta sentence and its
mutation probe. It was the only public helper nothing else used (`FingerBox` builds pockets through
`mortises`), so removing it shrinks the contract that has to be stated without weakening the
kernel. Cutting the derivable clauses "widening tabs and narrowing slots", "so a cut tab fills its
cut pocket exactly", "so all twelve shared edges mate" and the redundant opening sentence funded
the rest.

Cost: 494 -> 472 human-effective LOC (floor 450), 142 -> 137 tests, meta 489 -> 487 words. Removing
`slots` briefly broke the build, since the private `nominal` helper used by `mates` sat inside the
removed span; restored and rebuilt.

Re-verified after the change: mutation battery 21 of 21 killed with 0 survivors, base state 137 of
137 new tests failing, solution state 124 base and 137 new all passing, both offline as uid 1000.

### Round 4 — Test Fairness 1 of 137 unfair (mates on empty input)

Down from 33. The last one was real: meta named empty-list rejection for `complement`, `profile`
and `mortises`, but `mates([], [])` was asserted to return falsy without throwing, which pins an
author choice between "invalid" and "vacuously true".

Fixed by making the API uniform rather than by deleting the test: `mates` now rejects an empty
partition exactly like its three siblings, meta names it in the same clause, and the test asserts
the rejection. A second test covers an empty partition on one side only. Two mutation probes were
added to keep both honest ("mates answers false on empty instead of rejecting" kills 2, "divider
accepted at the far wall" kills 2).

Three of the four advisory coverage suggestions were also taken, since each maps to an
already-stated behavior: a divider exactly at the width and a negative divider (the prompt says
strictly between zero and the width), seam identity (each of the 24 face-edge names appears on
exactly one of the twelve seams), and `cutLength` on a divided box (the prompt says report walks
children). The fourth, pushing dimension validation through APIs that do not take those arguments,
was skipped as it would assert parameters that do not exist.

Cost: 137 -> 142 tests, 472 -> 474 human-effective LOC, meta 487 -> 488 words. Mutation battery now
23 probes, 23 killed, 0 survivors. Base state fails all 142; solution state passes 124 base and 142
new; 3 runs of each state, identical.

### Round 5 — Test Fairness 1 of 142 unfair (zero-length path hygiene)

The flagged test was my own leftover. It was written in round 1 to guard the zero-length skip in
`JointedRectangle`; when the mutation battery proved that guard was dead code the guard went, the
test was renamed, and it survived asserting an internal hygiene property ("every path has positive
length") that the prompt never states and that `ConnectTheDots` does not establish either. Deleted
rather than described: it constrains representation, not the outline, and the corner resolution
already guarantees it structurally.

Two of the four advisory suggestions turned out to expose a real inconsistency rather than a gap in
coverage. meta says every function rejects a negative kerf, but only `fingers` checked it;
`complement`, `mates` and `mortises` accepted one silently, and `mortises` only tested the kerf
against the thickness. A shared `allowedKerf` guard now backs the stated contract across all four,
with tests through each and a mutation probe (kills 5). Also added, all mapping to stated rules:
negative `fingerWidth` and negative `thickness` through `fingers`, both through the two model
constructors, and a hand-built nested model proving `report` counts only children carrying `joints`.
The third suggestion (malformed non-empty partitions) was skipped because no such rule is stated;
that would be inventing a requirement.

Cost: 142 -> 150 tests, 474 -> 482 human-effective LOC, meta unchanged at 488 words. Mutation
battery 24 probes, 24 killed, 0 survivors, after re-anchoring the `mates` probe whose anchor text
the new kerf guard had shifted.

### Round 6 — Test Fairness 2 of 150 unfair (report.cutLength undefined)

Both flagged tests had one cause: meta named `cutLength` as a report field but never said what it
measures, so pinning it to the sum of every path length was an author choice. The report clause now
reads "counting those carrying `joints` as `faces`, their `tabs` and `slots`, and the total length
of every path it walks as `cutLength`", which is exactly what the reference computes
(`measure.modelPathLength` over the walked model, pockets included).

Also closed a description/implementation gap the suggestions pointed at. The old clause implied
`complement` and `mates` reject a kerf as wide as a finger, but neither can evaluate that: they
receive spans, not a nominal finger width, and a compensated span has no single "finger width" to
compare against. Rather than invent an ambiguous rule, the clause is now scoped to the functions
that can evaluate each limit: a negative kerf anywhere, the finger-width limit where an edge is
being divided, the thickness limit in `mortises`. Two of the three coverage suggestions were taken
(negative width, depth and height through `FingerBox`; an open divided box cutting pockets into
bottom, front and back with no top host); the third is now moot after the rescoping.

Cost: 150 -> 154 tests, meta 488 -> 485 words. Word budget was reclaimed by dropping the "half a
kerf inside the nominal boundary" lead-in, which the two explicit pocket measurements had made
redundant. Solution unchanged at 482 human-effective LOC; mutation battery still 24 of 24 killed.

### Round 7 — Test Fairness PASS, all five coverage suggestions taken

No unfair tests. All five advisory suggestions mapped to already-stated behavior, so all five were
implemented; several strengthened tests earlier rounds had called shallow.

- Direct validation at each entry point: negative `fingerWidth` in `fingerCount`, negative width and
  height and non-positive thickness in `JointedRectangle`, negative thickness in `profile` and
  `mortises`, and a kerf strictly greater than the mortise thickness.
- `cutLength` on a plain `Rectangle` still equals its path length even though the joint counts are
  zero, which is what "the total length of every path it walks" means.
- Divider host symmetry: pockets absent from both side faces, and pocket placement checked on all
  four hosts rather than only `bottom`, plus the wall-host pocket run along its height.
- Corner geometry depth: the swallowed corner is now checked against both path ends rather than
  origins only, and each of the four orientations is checked for a point at exactly one thickness
  inward as well as one on the edge line.
- Open-box metadata: no remaining seam references the removed `top` face on either side.

One solution change fell out of the first item. meta says every model rejects a thickness or finger
width not above zero, but `JointedRectangle` only validated them indirectly, by way of the finger
call, so a rectangle with no jointed edge accepted both silently. The constructor now validates
unconditionally, matching the stated rule, with a mutation probe (kills 2).

Cost: 154 -> 169 tests, 482 -> 484 human-effective LOC, meta unchanged. Mutation battery 25 probes,
25 killed, 0 survivors.

**Environment note, not an artifact defect.** One run in this round reported zero test cases. The
host root filesystem had filled to 0 MB free, so mocha opened the JUnit file and then could not
write it; the tool itself reported ENOSPC on the next command. After clearing this session's own
scratch checkouts and docker images (90% used, 59 GB free), 8 consecutive runs across both states
were identical, on top of 6 earlier reruns of the same image. Nothing in the deliverables changed
between the empty run and the clean ones. Worth remembering: a zero-case JUnit result is a disk
symptom before it is a test symptom.

### Round 8 — Test Fairness PASS, four of five suggestions taken, one declined on evidence

- Remaining non-positive cases: negative `fingers` length, zero `mortises` thickness, zero
  `FingerBox` thickness.
- Model kerf limits: `JointedRectangle` and `FingerBox` reject a kerf reaching the divided finger
  width, not only a negative one.
- Face polarity symmetry: `back`, `top` and `right` now checked directly, so a face-specific wiring
  mistake cannot hide behind the `front` / `bottom` / `left` representatives.
- Multiple dividers: each panel is asserted to have its own pocket child in all four hosts, centred
  on its own supplied position, rather than only that both names exist.

**Declined: "also assert `seams[i].slotted[1] !== 'top'".** That would fail a correct
implementation. `slotted[1]` is an EDGE id, not a face id, and the open box legitimately keeps
`{tabbed: ["back","bottom"], slotted: ["bottom","top"]}` — the bottom face's TOP EDGE, which mates
the back wall and has nothing to do with the removed top face. The existing test already asserts the
three that are correct: `tabbed[0]`, `slotted[0]` and `tabbed[1]` are never `top`.

**Also declined: NaN validation.** `positive` uses `!(value > 0)`, so NaN is rejected for dimensions,
but `allowedKerf` uses `kerf < 0`, so a NaN kerf passes. Testing NaN would either assert an
inconsistency or require reading "not above zero" as covering NaN, which is a stretch the prompt
does not make. Left alone deliberately rather than half-covered.

Cost: 169 -> 178 tests. Solution unchanged at 484 human-effective LOC; mutation battery still 25 of
25 killed.

**The worktree was removed externally again**, as it was at the start of this session, so the clone
had to be rebuilt from BASE_COMMIT plus the two patches before this round could run. The five
deliverables were untouched and re-applied cleanly, which is itself a useful check that the patches
are self-sufficient. Note this cost a `git update-index --chmod=+x test.sh` to restore the 100755
mode bit, since a fresh clone plus `git apply` does not preserve it in the index; the regenerated
`test.patch` was verified to carry `new file mode 100755`.

### Round 9 — Test Fairness 1 of 178 unfair (mortise path count)

The flagged assertion required `Mortise1` to hold exactly four paths. The prompt fixes the pocket's
closure, orientation, centring and extents but never its internal segmentation, and nothing forbids
a collinear split, so the count was an author choice. Deleted: the pocket geometry is already pinned
by the x and y extent tests, so nothing was lost. The sibling "unjointed rectangle has four lines"
test stays, since the reviewer confirmed the plain-rectangle representation is repo-discoverable
from `Rectangle.ts`.

Three of the four advisory suggestions taken, and the second one exposed another gap between the
description and the code: meta says a negative kerf is rejected "anywhere", but `JointedRectangle`
only reached the kerf check by way of a jointed edge, so a rectangle with no `edges` accepted a
negative kerf silently. The constructor now validates it directly, with a mutation probe. Also added
`FingerBox` rejection of a zero and negative finger width and a negative kerf, and the outer-size
test now asserts each face's high extents rather than only its minima.

**Declined again: "assert `seam.slotted[1]` is never `top`".** The suggestion has now appeared twice
and is still wrong. Dumping the open box's seams shows
`{tabbed: ["back","bottom"], slotted: ["bottom","top"]}` — `slotted[1]` is an EDGE id, and that is
the bottom face's top edge, which mates the back wall and is unrelated to the removed top FACE. The
assertion would fail a correct implementation. The three that are correct are already asserted:
`tabbed[0]`, `slotted[0]` and `tabbed[1]` are never `top`.

Cost: 178 -> 182 tests, 484 -> 486 human-effective LOC. Mutation battery 26 probes, 26 killed, 0
survivors.

### Round 10 — Test Fairness 16 tests unfair (mortise container shape)

Two findings, one cause: every mortise test reaches a pocket through `.models.MortiseN`, but meta
only said pockets are NAMED `Mortise1` upward, never that each is a child model. The reviewer's
citation is right that Maker.js allows either shape: `schema.ts` lets a model hold direct `paths` or
recursive `models`, and `Slot.ts` keeps component paths direct unless isolation is requested. A
flattened implementation would be geometrically identical and fail all sixteen.

Fixed in the description, which is where the gap was: mortises now "returns a model whose child
models, `Mortise1` upward, close one pocket over every tab". That one clause also settles the second
finding, the nested level inside a divider host, because meta already says the host receives the
mortise model as a child named after the panel, so `host.models.divider1.models.Mortise1` follows
from the two statements together. Rewriting sixteen tests to measure pockets in aggregate was the
alternative and would have lost the per-pocket geometry that makes them worth having.

Both remaining suggestions taken. The first was a real miss: my round-7 "negative finger width" test
was inserted into the `fingers` block, not `fingerCount`, because the anchor I edited against did not
match, so `fingerCount` was only ever tested at zero. Now covered directly. Also added a direct
kerf-compensated `JointedRectangle` outline assertion, pinning `Edge1` through `Edge3` on the shifted
boundaries (`20.5`, `39.5`) while the outer size stays 100 by 40, rather than relying on FingerBox
seam mating to exercise kerf through the model.

Cost: 182 -> 184 tests, meta 486 -> 490 words. Solution and mutation battery unchanged at 486
human-effective LOC and 26 of 26 killed.

⭐ Standing lesson for structured returns: naming the elements of a composite result is not the same
as specifying its SHAPE. Every level of nesting a test walks has to be stated, not just the leaf
names. This is the same class as the earlier `profile` finding, where the point array needed stating,
and the `seams` finding, where the `[face, edge]` pair did.

### Round 11 — Test Fairness PASS, three suggestions taken, one declined again

⭐ **The first suggestion caught a silent tooling failure of mine, and it is the most useful thing
this round.** The reviewer said `fingerCount` had no negative finger-width case and `fingers` had no
negative length case. I had "added" both in earlier rounds and said so. Checking the artifacts, both
were absent: my edit scripts applied `str.replace` with no assertion, so when an anchor did not match
the insertion silently no-opped. The anchor I kept using carried the label `'zero finger width'`
while the file said `'must be greater than zero'`. That is the same mechanism that put the round-7
test in the wrong describe block. Every edit now asserts its anchor before substituting, and the
regenerated patch was grepped for both strings to confirm they landed.

Also taken: omitted kerf compared against explicit zero for `mates` and `mortises` (previously only
`fingers` checked the stated default directly), and a report case where the root carries its own
paths as well as a jointed child, confirming `cutLength` spans both levels while the joint counts
follow only the child carrying `joints`.

**Declined a third time: "assert `seams[i].slotted[1] !== 'top'".** The open box's own seam list
contains `{tabbed: ["back","bottom"], slotted: ["bottom","top"]}`. `slotted[1]` is an EDGE id; that
entry is the bottom face's top edge, which mates the back wall and has nothing to do with the removed
top FACE. The assertion would fail a correct implementation. The three correct ones are asserted:
`tabbed[0]`, `slotted[0]` and `tabbed[1]` are never `top`.

Cost: 184 -> 189 tests. Solution, meta and mutation battery unchanged: 486 human-effective LOC, 490
words, 26 of 26 killed.

⭐ Process lesson worth keeping: a silent no-op edit is indistinguishable from a successful one unless
the tool asserts. Two rounds of my own reporting were wrong because of it. Assert the anchor, then
verify the generated artifact, not the intent.

### Round 12 — Test Fairness PASS, two suggestions taken, the recurring one answered in code

Zero finger width is now tested directly on `fingers` and on `JointedRectangle` (both previously had
only the negative variant), and `mates([], nonEmpty)` mirrors the existing right-side check so the
either-side guard cannot be asymmetric.

**The `slotted[1] !== 'top'` suggestion appeared for the fourth time.** It is still wrong for the
same reason, so instead of explaining it in review prose again I encoded the distinction as a test:
"should keep the bottom face joined to the back wall in an open box" asserts that exactly one seam
`{tabbed: ["back","bottom"], slotted: ["bottom","top"]}` SURVIVES. A future reader, or checker, now
meets the fact in the suite rather than in an argument.

The root of the confusion is a genuine naming collision worth recording: `top` is both a FACE id and
a rectangle EDGE id. On the bottom face, the edge named `top` is its far edge in local 2D, which
mates the back wall and has nothing to do with the box's top face. Renaming either set would be worse
(the edge names are the natural rectangle names and are stated in meta for `JointedRectangle`), so
the collision stays and is now pinned by a test.

Cost: 189 -> 193 tests. Solution, meta and mutation battery unchanged: 486 human-effective LOC, 490
words, 26 of 26 killed. Each addition was verified by grepping the regenerated patch, not by trusting
the edit script.

### Round 13 — Category check FAILED: the description read as documentation, not a request

The checker said the description explains existing capabilities rather than asking for anything new,
and suggested category `none`. The category is right (`feature-request`, net-new public API); the
description was at fault, and this is self-inflicted. In round 3 I cut the framing sentence to
reclaim words for the fairness fixes, so the body opened straight into
"`joinery.fingerCount(length, fingerWidth)` divides an edge into..." — present tense, no statement
that none of it exists. Read cold, that is API documentation.

Restored an explicit ask as the opening: "Maker.js cannot cut finger joints. Add a `joinery`
namespace and the models `JointedRectangle` and `FingerBox`." Both halves matter: the first says the
capability is absent, the second is imperative.

The sixteen words were paid for by wording-only compression elsewhere (semicolons for clauses, "here"
for "above", "slot-leading" for "edges all starting with a slot", and a tighter report clause). No
behavioural statement was touched: all nineteen tested contracts were grepped out of the rewritten
file afterwards and every one is still present. meta 490 -> 491 words, still six paragraphs, longest
122.

Both patches regenerate byte-identical, so tests and solution are untouched and no revalidation was
needed; the suite still runs 124 base plus 193 new.

⭐ Lesson: word-budget pressure has a direction. Every time I trimmed for the fairness checker I cut
framing first, because framing is never what a fairness reviewer cites. But framing is exactly what
the CATEGORY checker reads. A spec-dense description that never says "add" will be classified as
documentation no matter how correct it is. Keep one imperative sentence that names the gap, and treat
it as load-bearing rather than as slack.

## Why this repo

Free repo pick (the user confirmed Task51's slot is not pinned and that the previous pgmpy
submission was rejected/blocked, so pgmpy was avoided). Requirements applied: a repo never used
anywhere under this workspace, >=500 stars, permissive single license, a source commit inside 12
months, and a deterministic offline suite.

Repos screened and killed before this one, with the gate that killed each:

| Repo | Gate | Detail |
| --- | --- | --- |
| deepcharles/ruptures | LOC ceiling | 2.9k LOC of Python, far under the depth proxy; Cython + setuptools_scm |
| TUDelft-CNS-ATM/bluesky | **license** | root LICENSE is MIT but every file in `bluesky/test/` is stamped "SPARKL Limited. All Rights Reserved ... GNU General Public License v3"; a multi-license repo with a non-allowed license is a reject, and the contaminated files are exactly the ones base mode runs |
| inducer/loopy | environment | git submodule (`loopy/target/c/compyte`) + pyopencl-dependent suite + islpy C binding |
| scverse/anndata | crowding | 83 open PRs over a mature data-structure API |
| NREL/floris, CalebBell/fluids | stars | 297 and 449, under the 500 floor (floris also moved org) |
| gumyr/build123d, pymatgen, mne-python | env / wall-clock | OCP or multi-hundred-test suites that cannot finish inside the Environment Quality budget |

maker.js won on environment: 124 tests in 8.6 s, pure TypeScript, no native dependencies, and no
network anywhere in the suite.

## Exclusivity and maintainer philosophy

Canonical org resolved (`microsoft/maker.js`, no redirect). Searched PRs and issues in all states
for tab, kerf, cut order, gcode, cam, toolpath, nesting, lead-in, bridge. Enumerated all 16
branches and diffed each against master.

- No PR, in any state, implements joinery.
- Live or fenced areas, all avoided: combine and text (branches `combine`, `combine-sweep`,
  `combine-sweep-expand-wip`, plus WIP PR #642), dimensions (branch `dimensions`), gcode
  (issue #423 closed by the maintainer with "gcode is out of scope for Maker.js"), sheet nesting
  (issue #449 closed pointing at SVGnest), SVG import (issue #336 declined).
- Joinery is the one CAM feature the maintainer explicitly WANTS: issue #246 "Ability to add tabs
  for boxes", maintainer reply "Absolutely! I am intending on doing this, just need to find the
  time." That is Gate 8 satisfied by a maintainer-stated intent rather than an external spec.
- Only prior art in the repo is `docs/demos/js/tongue-and-groove.js`, 27 lines that clone a
  `Dogbone` into a row with `layout.cloneToRow`. It is the motivation, not the algorithm: no chain,
  no polarity, no kerf, no corner handling, no mating.
- Branch overlap with my footprint is limited to a handful of lines in `chain.ts` (`dimensions`
  +1, `combine-sweep-expand-wip` +9). My core machinery is three new files that no branch touches.

## Deduplication

No approved or in-flight problem anywhere under this workspace touches CAD, CAM, 2D geometry
assembly or joinery. Closest by mechanism is `asciimatics-diagram-renderer` (a per-cell kernel
feeding a renderer). This differs in domain, in kernel (an arithmetic partition carrying parity and
kerf), and in verification surface (structural complementarity between two independently generated
parts).

## The design

One kernel, `joinery.fingers`, drives every surface: the profile tracer, the slot and mortise
builders, the rectangle assembler, the box, and the `mates` verifier. A local fix to any one surface
regresses another because they all read the same partition.

Traps, each mutation-proved below:

1. The finger count must be ODD, minimum three, rounding ties up. `Math.round(length / width)` is
   the obvious line and produces even counts.
2. Kerf moves interior boundaries toward the neighbouring SLOT, so tabs widen and slots narrow, and
   the outer boundaries never move. Widening everything uniformly looks right and fails only the
   fit assertions. End fingers therefore take half a kerf, interior ones a full kerf.
3. Fingers are equal and span the edge exactly. Laying out fingers of the nominal `fingerWidth` and
   leaving a remainder is the natural mistake, and it surfaces as a mating failure on a different
   face.
4. Mortises are the mate's pockets, not the panel's own slots, and they are NARROWED by the kerf
   while the tabs entering them are WIDENED. Getting the direction right on one side and wrong on
   the other still assembles on paper.
5. Corner resolution: a slot at a corner swallows that corner, and where two slotted edges meet the
   outline turns at the point set in by the thickness from both. Emitting both profiles naively
   produces an outline that doubles back on itself.

Trap 1 and trap 3 are interdependent (the count sets the width). Trap 2 and trap 4 are the same
kerf rule pointing in opposite directions on the two mating parts.

## Verification

Mutation battery (`Task51/mutate.py`, 26 mutations, one per stated rule): **26 killed, 0 survivors**,
baseline restored clean. One mutation initially survived, "zero length paths emitted", which proved
the zero-length guard in `JointedRectangle` was dead code once the corner resolution deduped
structurally. The guard was removed, the matching clause was dropped from meta.md, and the two
tests naming it were renamed to what they actually assert.

False-positive audit, applied while writing the tests rather than after a batch:

- Fixed-point discriminator: `complement` is the only transformation verb, and the suite asserts the
  involution (applying it twice returns the original) on both the kerfed and unkerfed partitions, so
  an implementation that only flips the `tab` flags cannot pass.
- Error contracts: the description pins one rule, "invalid arguments are rejected with a message
  containing `joinery:`", and the tests assert that substring. Asserting my exact wording would have
  been a hidden requirement, and asserting a bare throw would pass vacuously on base, where every
  call raises TypeError.
- Implementation choices unpinned: the divider pocket tests originally asserted `.origin` equals
  `[position, 0]`, which would have failed a correct implementation that baked the offset into the
  points. They now clone, `originate`, and assert absolute extents.
- Unstated names removed: `Slot1` and `Mortise1` are now named in meta.md, and `seams` is described
  as holding a `tabbed` and a `slotted` pair.

## Validation matrix

All runs offline (`--network none`) and non-root (`--user 1000:1000`).

| State | `test.sh base` | `test.sh new` |
| --- | --- | --- |
| base + test.patch | 124 cases, 0 failures | 142 cases, **142 failures** |
| + solution.patch | 124 cases, 0 failures | 142 cases, 0 failures |

Every one of the 142 new tests fails on base, none vacuously; the failure is
"Cannot read properties of undefined (reading 'fingerCount')", a missing feature rather than an
import error. Patches apply and unapply cleanly in both orders. Flakiness: 3 consecutive Docker runs
of both modes plus 4 earlier runs, all identical.

Effective LOC (`effective_loc_check.py`): **494 human-effective**, 720 raw, 5 files.

## Environment Quality

The gate runs the repo's own `npm test` on the unpatched tree and demands exit 0. maker.js fails
that out of the box in a sandbox for two reasons, both fixed in the Dockerfile:

1. The base image sets `NODE_ENV=production`, so `npm install` omits devDependencies. The nested
   `npm install` inside `npm test` then PRUNES mocha and typescript ("removed 320 packages"). Fixed
   with `ENV NODE_ENV=development`.
2. `npm run build` and `npm run docs` shell out to `npx -p typescript@4.1.3 -p typedoc@0.18.0`,
   which hits the registry. Fixed by warming that exact npx tree at image build time into a shared,
   world-readable cache (`ENV NPM_CONFIG_CACHE=/app/.npm-cache`, `ENV HOME=/app`).

Verified: vanilla `npm test`, no patches, `--network none`, uid 1000, builds, runs 124 tests and
generates the typedoc output, exit 0.

`chmod -R a+rwX /app` is also required, otherwise tsc cannot create `packages/maker.js/dist` as
uid 1000.

## Deviations and open risks

- **meta.md is 459 words**, over the 200-word guidance though under the 500-word hard cap. This is
  a method-call-tested library API, so the module, type and method names are the contract and the
  alignment check needs them enumerated; the approved corpus carries 241- and 309-word precedents.
  Cutting to 200 would mean deleting a clause describing a tested behavior, which is the strictly
  worse reject (hidden requirement / Test Fairness FAIL). The alternative, cutting scope on meta,
  tests and solution together, would drop roughly 45 effective LOC and put the submission under the
  450 design floor. Kernel rules are front-loaded and the last sentence is not load-bearing.
- **Pass rate is unmeasured.** The design targets the corpus mode of about 1 in 10. If a batch comes
  back above 40%, the lever is the corner-resolution rule and the mortise direction, not more
  breadth.
- The comment density matches the repo: maker.js doc-comments every public symbol with `@param` and
  Example blocks (see `models/Rectangle.ts`). Test bodies carry no comments, matching the repo's
  existing tests. Comments count zero toward effective LOC, so the 494 figure is code only.

## Assumptions logged

- Autonomous one-shot mode; no pauses at the DESIGN.md gate.
- Faces are emitted at their own local origins rather than laid out into a sheet, so no arbitrary
  layout convention enters the contract.
- Divider positions are supplied by the caller rather than derived from an even-spacing rule, which
  keeps a spacing formula out of meta.md and off the fairness surface.
