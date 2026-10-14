# cwerg-fe-address-constants - eval results

No platform batch yet (slice awaits the platform precheck).

## Local validation (2026-09-29, slice)

Image `factory-cwerg-fe-address-constants` built from a fresh `git clone` at BASE with test.patch
applied (no solution). Cold `docker build --no-cache`: 4m22s. `git status` in the image shows only
`FE/AddrTest/` and `test.sh`. All runs `--network none`; solution applied with `git apply` as root in
the running container, test.sh run via `setpriv` as uid 0, 1000 and unmapped 4242.

| State | Mode | uid 0 | uid 1000 | uid 4242 |
|---|---|---|---|---|
| no solution | base (326) | 0 fail | 0 fail | 0 fail |
| no solution | new (36) | 36 fail | 36 fail | 36 fail |
| solution | base (326) | 0 fail | 0 fail | 0 fail |
| solution | new (36) | 0 fail | 0 fail | 0 fail |

Round 1 found 3 new-mode cases passing on base (`static` parity.x64/a64/a32): both front ends
failed and left empty IR files that diffed equal. test.sh now deletes the IR of a failed compile and
the parity case recompiles; round 2 results below.

Round 2 (after the fix): no solution base 326/0 fail and new 36/36 fail for all three uids; solution base 326/0 and new 36/0 for all three uids. Test id sets identical with and without the solution; no `::` in any id.

## Trap reproduction (natural-but-wrong mutants of the Python FE, new mode)

| Mutant | cases failed | programs |
|---|---|---|
| M1 span elimination drops the front's value | 6 | tables |
| M2 offset span not read through | 9 | static, tables |
| M2b offset span reuses the global's content | 12 | static, tables |
| M3 read-through of `global!` from its initializer | 6 | runtime |
| M5 address equality on the symbol only | 12 | static, runtime |

## LOC
`python3 .claude/hooks/effective_loc_check.py problems/cwerg-fe-address-constants/solution.patch`:
251 human-effective, 299 raw, 10 files, padding-floor 133.

## Timing
test.sh base ~2m45s, new ~40s per run in Docker (x86 host, qemu for a64/a32).

## Local validation round 3 (2026-09-29, after platform precheck round 1)

Fresh container from a clean base image, root, `--network none`.

| State | Mode | result |
|---|---|---|
| no solution | new | 45/45 fail |
| no solution | base | 322, 0 fail |
| solution | new | 45, 0 fail (x4 runs, also uid 4242) |
| solution | base | 322, 0 fail (x3 runs) |

Old solution + new `deref` program: 9/9 cells fail (py assertion, cc segfault).

## Local validation round 4 (2026-09-29, after Solution Quality round 2)

Fresh container, root, `--network none`. No solution: new 54/54 fail, base 322/0 fail. Solution:
new 54/0 (x4, also uid 4242), base 322/0 (x3). Round-2 solution vs these tests: 15 fail
(aggregate 9/9, deref cc + parity on all three targets).

## Local validation round 5 (2026-09-30, after platform round 3)

Fresh container, root, `--network none`. No solution: new 54/54 fail, base 322/0. Solution: new
54/0 (x3, also uid 4242), base 322/0 (x2). Round-3 solution vs these tests: 9 fail (the whole
deref program on every target, py and cc).

## Local validation round 6 (2026-09-30, after platform round 4)

Fresh container, root, `--network none`. No solution: new 63/63 fail, base 322/0. Solution: new
63/0 (x3, also uid 4242), base 322/0 (x2). Round-4 solution vs these tests: 9 fail (all of
`spancopy` on every target, py, cc and parity).

## Batch 1 (2026-10-01): 10 Nova, 0/10

Saved in agent-runs/1/. Baseline 322/322 on every run (the four excluded parity programs did not
come back). Median ~225 model requests per run (148-373), 6-16 source files touched.

| Run (dir) | new passed | failed programs | note |
|---|---|---|---|
| 1 | 36/63 | aggregate, deref, spancopy | |
| 2 | 39/63 | deref, spancopy, tables | |
| 3 | 36/63 | aggregate, deref, spancopy | |
| 4 | 39/63 | deref, spancopy, tables | |
| 5 | 36/63 | aggregate, deref, spancopy | |
| 6 | 12/63 | all seven | cc side broken |
| 7 | 33/63 | aggregate(6), deref, spancopy, tables | |
| 8 | 39/63 | deref, spancopy, tables | |
| 9 | 30/63 | aggregate, deref, spancopy, tables | |
| 10 | 45/63 | deref, spancopy | near-passer |

Universal kills (10/10): spancopy line 29 `global picked = spans[1]` (py "do not know how to convert
span related node", cc "Unhandled span replacement ExprFront", the pre-existing span-lowering gap);
deref `front(views[0])` (py, 9/10) and `front(vw.items)` (cc, 7/10), i.e. spans stored in vec / rec
literal slots, the pre-existing raw-vs-converted lookup divergence. Designed traps: aggregate
(`global copy = p^`, `sp[1]` rec read, default nested rec) killed 5; tables (`front(middle)` of a span
global) killed 6.

Replay of all 10 saved solutions (worktrees/_cw_bak/replay, probes split by suspect lines): with
spans-in-literal `front` asserts and `picked` removed, run 10 passes everything -> 1/10. Keeping
only the rec-literal case still gives 0/10.

## Local validation round 7 (2026-10-01, after the Expr3 Solution Quality finding)

Fresh container, root, `--network none`. No solution: new 81/81 fail. Solution: new 81/0 (x3),
base 322/0 (x3). Replay of the 10 batch-1 solutions on the current suite: run 10 passes everything,
the other 9 still fail aggregate and/or tables (designed traps) -> expected re-eval 1/10.

## Local validation round 8 (2026-10-01, output parity + mypy)

Fresh containers, root, `--network none`. test.sh: IR diff replaced by run-output comparison,
base IR parity removed (base = 242). No solution: new 81/81 fail, base 242/0. Reference: new 81/0
(x3), base 242/0 (x2). Batch-1 run 10 replayed: new 81/0, base 242/0.

## Re-eval 2 (2026-10-01): batch-1 solutions on the cut suite, 1/10 -> FP panel voids it

Saved in agent-runs/2/ (same solution patches as batch 1). Run 10 81/81 + base 242/242 (pass);
others: 4, 8 75/81 (tables); 1 72/81 (aggregate); 3 72/81 + base 177/242 (agent committed FE/build_cc
artefacts); 2 69/81 (deref, tables); 5, 9 66/81; 7 60/81; 6 0/81. Matches the local replay exactly.

FP panel: run 10 = false positive (adjudicator, high confidence; judge #1 genuine, judge #2 FP).
Cited defect: C++ `GetValForVecAtPos` gives 0 for a gap in `{[6]u32: 1=10, 3=30, 5=50}` so
`@a[2]^` folds to 0 (py 10). Verified on the UNPATCHED base image: `static_assert a[2] == 10` on the
same literal passes in py and fails in cc ("EvalNum[0_u32]") with no address constants involved, so
the defect is pre-existing and reachable through plain indexing. The reference fixes it (round 9).

## Batch 4 (2026-10-03): fresh 10 Nova on the capped meta, graded on the 90-case suite -> 1/10, FP-voided

Saved in agent-runs/4/ (new solutions; platform label "re-eval 1"). Median ~245 tool calls.

| Run | new | base | failed programs / note |
|---|---|---|---|
| 1 | 81/90 | 242 | tables |
| 2 | 66/90 | 238 | defspan, spancopy, tables; py breaks sum_tagged, flate |
| 3 | 75/90 | 242 | aggregate, tables |
| 4 | 63/90 | 242 | aggregate, defspan, spancopy |
| 5 | 9/90 | 238 | nearly all; py breaks sum_tagged, flate |
| 6 | 90/90 | 242 | PASS; FP-voided (below) |
| 7 | 90/90 | 226 | base regressions: cc segfaults bigint/flate, vec_gen type error |
| 8 | 3/90 | 242 | nearly all |
| 9 | 66/90 | 242 | aggregate, defspan, spancopy |
| 10 | 9/90 | 238 | nearly all; py breaks sum_tagged, flate |

FP panel voided run 6: C++ crashes (ConstGetSpan assert) on `global copy = psrc^` of a record with a
span field, then `len(copy.items)`. Verified: base C++ crashes the same way on a plain
`global copy = src` with no address constants; the reference only passes because it fixes the
record-field lookup. Judge-c's narrowing-cast index probe was dismissed because the reference
Python fails it too ("shared spec gap").

## Batch 5 (2026-10-09): 8 Nova on the NEW models (post-revert gate: Nova must be 0/8)

Saved in agent-runs/5/. Many artifacts failed to download (_download-errors.txt).

| Run | new | base | seq length | note |
|---|---|---|---|---|
| 1 (Nova #8) | 81/90 | 242/242 | 1,062k | aggregate |
| 2 (Nova #7) | 90/90 | 242/242 | 927k | NOVA PASS (platform confirmed) |
| 3 (Nova #6) | 0/90 | 0/242 | 922k | grading wall-clock budget exceeded; patch not downloaded |
| 4 (Nova #5) | 3/90 | 242/242 | 1,053k | fail |
| 5 (Nova #4) | 81/90 | 242/242 | 909k | aggregate |
| 6 (Nova #3) | 0/90 | - | 793k | fail: cc crashes, py AttributeError get_uint_size |
| 7 (Nova #2) | 72/90 | 242/242 | 1,201k | aggregate, spancopy |
| 8 (Nova #1) | 9/90 | 242/242 | (incomplete) | fail |

Sequence length average ~980k (858k counting run 8 as 0), far above the 256k bar. Nova gate
FAILED: run 2 passes the full suite in replay -> harden before running Orion.

## Harden round 1 under the new gate (2026-10-09)

New contract: same-global ordering constants + cross-global ptr_diff/ordering in a global initializer
is a compile error at the expression. 96 new-mode cases (+3 reject programs x py/cc).
Clean room: nosol new 96/96 fail, base 242/0; reference new 96/0 x3, base 242/0.
Saved Nova replays (no meta exposure, L35): b5r2 72/96, b4r6 72/96, b5r1 63/96.

## Batch 6 (2026-10-10): post-harden, 6 Nova + 4 Orion on the new models

Saved in agent-runs/6/ (11 artifacts failed to download; Nova #1, #4 and Orion #1, #2 absent).

| Run | new | base | seq length | note |
|---|---|---|---|---|
| Nova #8 | 78/96 | 242 | 1,129k | aggregate, defspan, spancopy |
| Nova #7 | 96/96 | 236/242 | 792k | fail: base regressions |
| Nova #6 | 15/96 | - | 1,061k | most programs |
| Nova #5 | 90/96 | 242 | 1,206k | aggregate |
| Nova #3 | 66/96 | - | 1,049k | aggregate, defspan, deref, spancopy |
| Nova #2 | 90/96 | 242 | 1,151k | deref |
| Orion #6 | 96/96 | 242 | 148k | PASS |
| Orion #5 | 96/96 | 242 | 149k | PASS |
| Orion #4 | 96/96 | 242 | 170k | PASS |
| Orion #3 | 87/96 | 242 | 154k | aggregate |

Gate: Nova 0/6 (needs 8 runs at 0), Orion 3/4 -> too easy for Orion (needs exactly 1/4).
Replay of the 5 Auto Review T4 probes (index via `^`, function-level cross-global ptr_diff,
vec / vec-field span aliasing under mutation, cross-global `<` and `>=` rejects) against all 8
downloadable solutions: zero kills (every agent passes every probe).

## Batch 7 (2026-10-10): after harden round 2 + humanized meta r3, Nova only so far

Saved in agent-runs/7/ (5 Nova exported; folder names do not match run numbers; some artifacts failed to download).

| Folder | Run | new | base | seq length | failed programs |
|---|---|---|---|---|---|
| Nova_Nova_1 | Nova #1 | 109/136 | 242 | 1,033k | aggregate, defspan, spancopy (`p^` copy of spans/bytes) |
| Nova_Nova_2 | Nova #8 | 130/136 | 242 | 1,121k | ring x64/a64 (element stride uses size, not aligned_size) |
| Nova_Nova_3 | Nova #6 | 121/136 | 242 | 1,062k | 15 failed (junit not downloaded) |
| Nova_Nova_4 | Nova #3 | 10/136 | 242 | 1,058k | every program (no `p^` aggregate copy, no BE addend) |
| Nova_Nova_5 | Nova #1 (2nd id) | 127/136 | 242 | 1,252k | aggregate |

Nova 0/5 so far, every run > 1M sequence length.

Coverage round (2026-10-10, tests + solution only, re-eval eligible): T4 ptr_inc(front(constant span)) and
a rec-literal span over a `global!` observed after mutation, added to tables. Replay of both cases on 8 saved
solutions (batch-6 Orion x4, batch-7 Nova x3) plus base: every solution passes, base fails.
S1 `front` of a default empty global span: reference fixed in both emitters (null pointer of pointer width).
Not tested: it kills 2 of 3 batch-6 Orion passers (py AssertionError, cc "not constant"), plus Nova #6 and
Nova #1(2nd) in different ways; n72 emits the span's own address. Kept out to protect the Orion 1/4 floor.

## Batch 8 (2026-10-10): 8 Nova on the 273-word meta

Nova 0/8. 7 runs fail a single program each (aggregate x2, ring x2 (x64/a64 stride), defspan+spancopy,
spancopy, tables-free); run #5 failed 117/126 on the C++ ELF `ASSERT(addend == 0, "NYI")` and was graded
"Undocumented Req". Contested (6 of the 7 other Nova runs fixed elf_unit.h themselves; repo's FE/Makefile_cc
runs FE programs through the C++ codegen tools).

## Batch 9 (2026-10-11): batch 8's 7 Nova + 1 new Nova (contested run replaced) + 4 Orion

Saved in agent-runs/9/. Nova_Nova_2..8 are byte-identical to batch-8 runs (trajectory md5). Nova_Nova_1 is the
new run. Patches for Nova 1, 2, 4, 5, 8 failed to download (Convex Server Error).

| Folder | verdict | new failed | max step tokens | notes |
|---|---|---|---|---|
| Nova_Nova_1 | PASS | 0/126 | 286k | NEW run; patch not downloaded |
| Nova_Nova_2 | FAIL | aggregate (9) | 275k | |
| Nova_Nova_3 | FAIL | ring x64/a64 (6) | 284k | |
| Nova_Nova_4 | FAIL | defspan + spancopy (18) | 452k | |
| Nova_Nova_5 | FAIL | ring x64/a64 (6) | 403k | |
| Nova_Nova_6 | FAIL | spancopy (9) | 283k | |
| Nova_Nova_7 | FAIL | no junit (unverified assumption) | 488k | BE addend not fixed |
| Nova_Nova_8 | FAIL | aggregate (9) | 276k | |
| Orion_Nova_1 | FAIL | tables py+output (6) | - | py emitter: ExprField of a global span in a rec literal |
| Orion_Nova_2 | FAIL | tables py+output (6) | - | same |
| Orion_Nova_3 | PASS | 0 | - | 709 eff LOC, signed addend in assemblers |
| Orion_Nova_4 | PASS | 0 | - | 647 eff LOC, signed addend in assemblers |

Gate: Nova 1/8 (fail), Orion 2/4 (too easy).

Probe round (probes13, 11 programs vs ref + O1-O4 + N3/N6/N7): the 3 coverage suggestions (ptr_inc from a
nested vector-field element, typed self/pointer-global cycles, equality over field/span-derived addresses),
plus aggregate-copy static_asserts, pointer-from-field copies, padded ring stride, span-copy static_asserts:
zero divergence on the passers (ringpad kills N3, spanstat kills N6, both already failing).
`front` of a default empty global span (emptyspan): kills O4 (py AssertionError unhandled ExprField), O1, O2,
N3, N6; O3 passes. Added as emptyspan_2c16e3_test.cw (with a front(full) static_assert so cc fails on base).
val22: nosol 135/135 fail, ref 135/0, base 242/0 x2. Then nestinc, eqfield, selfref (the 3 coverage partials; 0 kills on every saved patch) added: val23 nosol 162/162 fail, ref 162/0, base 242/0 x2. Expected re-eval: Orion 1/4 (O3). Nova 1 unknown.

## Batch 11 (2026-10-11): re-eval of batch 9 on the 162-case suite (ACCEPTED)

| Run | failed / 162 | failed programs | seq length |
|---|---|---|---|
| Nova #1 (new, contest replacement) | 6 | emptyspan | 1,583k |
| Nova #2 | 18 | aggregate, emptyspan | 1,026k |
| Nova #3 | 15 | emptyspan, ring (x64/a64) | 809k |
| Nova #4 | 27 | defspan, emptyspan, spancopy | 969k |
| Nova #5 | 12 | emptyspan, ring (x64/a64) | 913k |
| Nova #6 | 15 | emptyspan, spancopy | 792k |
| Nova #7 | 15 | aggregate, emptyspan (no eval-result) | 788k |
| Nova #8 (batch-9 pass) | 9 | emptyspan (py assert, cc segfault) | 1,077k |
| Orion #1 | 12 | emptyspan, tables | 178k |
| Orion #2 | 12 | emptyspan, tables | 178k |
| Orion #3 | 0 | PASS | 468k |
| Orion #4 | 6 | emptyspan | 145k |

Nova 0/8, Orion 1/4, Nova seq avg 995k. Per-program kills: emptyspan 11, aggregate 2, ring 2, spancopy 2,
tables 2, defspan 1; 12 programs killed nothing.
