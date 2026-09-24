# vrp-initial-clustering-roundtrip — feedback

STATUS (2026-09-23): DEAD - UNDER-FLOOR (machinery-absorbed). Shelved to rejected/ before any precheck.
The working core slice (reader inversion of clustered stops, open-shift start fix, translation of initial
individuals onto the clustered registry after pre_process, rosomaxa hook) measured **155 human-effective**
(`effective_loc_check.py`), 8 new tests green on the reference, fmt + clippy clean. The only remaining
genuine FINISH scope, required breaks in the reader, was prototyped: **168 human-effective** in total,
and it still cannot make the stated read-back law hold for a required break inside a clustered stop,
because the base writer renders such breaks inconsistently (a member is written as served during the
break; the break is "moved" onto the stop end) - inverting that means pinning a pre-existing writer
quirk. Hunter sketch was ~260; actual ~165-170, the usual 1.5-2x sketch overshoot (TOO-EASY
machinery-absorbed row): the reader reuses `Commute::to_domain` and `get_extra_time`, the solver
restore recomputes every schedule, and the translation is one grouping pass.

Milestones: [x] Gates 1/6 reproduced at BASE (probe, dev container factory-vrp-dev, target in volume
factory-vrp-target): (A) read_init_solution of the solver's own clustered output -> "commute property in
initial solution is not supported"; (B) unclustered init solution for the clustered problem, 0 and 200
generations -> fully unclustered result. [x] SIX-CHECK + exclusivity clean (canonical reinterpretcat/vrp,
508 stars). [x] DESIGN.md. [x] slice code + tests (reference). [ ] Docker clean room (not run: lane dead
on LOC before validation spend).

Measured facts worth keeping for any future vrp lane:
- write_pragmatic(read_init_solution(x)) == x already holds on base for unclustered solutions on CLOSED
  shifts; on OPEN shifts base reader overwrites the start activity's time with the last stop's first
  activity (`create_core_route`: `Tour::end()` returns the start on an open tour). henningms fork has the
  1-line fix (`actor.detail.end`).
- Solving with max_generations 0 and init size 1 writes the supplied initial solution back exactly
  (JSON-equal) once the translation exists: a deterministic end-to-end oracle for this repo.
- Base writer + required break inside a clustered stop produces an incoherent schedule
  (post_process unpacks members ignoring the reserved time; break_writer then "moves" the break).

## Decisions log (unattended; conservative choices recorded here)

- Removal-record check: the init reader copied `commute` into the core activity for ONE day in Oct 2021
  (a5988741 -> 60b3eecb) during unreleased clustering development; both commits first ship in v1.12.0, so the
  passthrough never existed in any release and there is no changelog removal note. Not the kira
  "reintroduces a removed capability" class. Recorded as a residual risk for the precheck.
- Dev builds run inside a container (docker disk) because / has ~10G free; worktree bind-mounted at /src.
- Fallback (LaurenzV/hayro, hayro-write optional-content baking) was NOT built in this run. A first look
  (clone, `hayro-write/src/{lib,primitive}.rs`, #1279) found: the visibility evaluator already exists in
  `hayro-interpret/src/ocg.rs` (OcgState: base state, ON/OFF arrays, OCMD AllOn/AnyOn/AnyOff/AllOff, BDC
  visibility stack), so that half is an in-repo oracle; the content lexer (`UntypedIter`) exposes no byte
  spans, so the rewriter must re-serialize operands; the render test suite depends on downloaded corpora
  and locally generated snapshots (base mode needs scoping). #1279's author (0xbe7a) runs LLM-driven
  differential validation of hayro-write and said he will fork it. Left for a fresh builder; clone removed.
- Owed to the human (not this run): the hunter's correction to `SATURATED-REPOS.md:870` (vrp Req 7 row is
  stale; master Build is green).
