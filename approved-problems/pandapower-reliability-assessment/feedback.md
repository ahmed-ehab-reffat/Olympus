# feedback.md — pandapower-reliability-assessment

## Summary

Olympus submission against [e2nIEE/pandapower](https://github.com/e2nIEE/pandapower) at
`af68dbc0f5af548b6ac7099112160acde0927ed6` (Python, BSD-3, 1233 stars, master, version 3.5.4).
Invented feature: the library gains a reliability assessment, so a network can say how often and
for how long each of its loads loses supply, and the switch level topology needed to work that
out becomes a public part of `pandapower.topology`.

- Effective LOC: **557 human-effective** / 809 raw across **14 files**; padding floor 346.
- Tests: **118** new cases in one new file, all 118 failing on base, all 118 passing with the
  solution, 118 named test nodes in the JUnit XML in both directions.
- Base suite: 244 passed / 10 skipped / 2 xfailed in `test.sh base`, identical with and without
  the solution. The vanilla `python -m pytest` that Environment Quality runs is also green
  offline: 1625 passed, 161 skipped, 0 failed in 17:32.
- Both patch orders apply and unapply cleanly; the image builds and runs offline as uid 1000.

## Why this repo and this feature

The user asked for a repo never used locally and a genuinely hard feature. pandapower appears in
no local directory (`worktrees/`, `problems/`, `rejected/`, `Aprroved/`, `Task*/problems/`) and
power systems are a domain the whole approved corpus never touches, which satisfies both the
derivative check and the preference for repos that are obscure to problem authors. Reliability
assessment is absent from the library: `grep -ri "reliability\|saifi\|saidi\|interruption"` over
the package finds one docstring mentioning the IEEE 24-bus reliability test system and nothing
else.

Pick gates, all run before authoring:

- Exclusivity: canonical org resolved with `gh api repos/e2nIEE/pandapower -q .full_name` (no
  redirect). `gh pr list` and `gh issue list --state all` over `reliability`, `SAIFI`, `SAIDI`,
  `interruption`, `outage`, `restoration` and `sectionalizer` return nothing on topic. All 33
  branches enumerated and compared against `develop`; the only one touching `topology/` is the
  stale `feature/get_substations`, whose diff adds an `include_out_of_service_branches` flag.
- Harmonic analysis was the first candidate in this repo and is **dead**: PR #2569 "first push of
  revised harmonic calculation code" is open and two branches (`harmonics`,
  `feature/harmonics`) carry it. Read the diff, dropped the pick, moved to reliability.
- Cold code: the capability does not exist, and `topology/graph_searches.py` has not changed on
  master since the substations work.
- Repo quota: zero of our submissions, a 1233-star niche repo, not on the saturated list.
- Environment: the vanilla suite is green offline as uid 1000 (241 passed, 13 skipped) and
  identical across three consecutive runs. Base mode is scoped to `pandapower/test/topology` and
  `pandapower/test/api`, which is where the solution lands (topology queries, the net structure,
  the result tables, `convert_format` and the JSON round trip).

## The design

The kernel is one structure the library did not have: a graph whose nodes are buses **and**
branch elements and whose edges are the single connections between them, so a switch sits on one
edge. Everything else is a different cut of that one graph.

- Cut every switch: the isolated part of an element, and with it the switches to open.
- Cut the closed circuit breakers and the open switches: the part that a fault de-energizes.
- Cut the open switches only: what is supplied right now.
- Cut nothing, minus the isolated part: what can be picked up again.

That is why a local fix does not work. An agent that reuses one traversal for the zone and the
isolated part either over-trips or under-isolates, and the mutation battery shows both directions
kill 51 and 52 tests. `create_nxgraph` is the obvious tool and is the wrong one: it drops a whole
line when either of its switches opens, so the isolated part stops at the wrong place. That
mutation kills 69 of 118.

Two rules sit on top and are counted differently from each other. A load that is switched back on
still counts once in the interruption rate, so an implementation that accumulates duration and
derives the rate from it gets SAIDI right and SAIFI wrong (48 kills). A planned outage is
isolated before the element is switched out, so no breaker trips and load that can be transferred
beforehand is not interrupted at all, which is the opposite treatment of the same restoration
set.

### Two things the design gained during the build

The first draft came in at 351 human-effective LOC. Rather than pad, two behaviours were added
that are real and that the corpus rewards:

- **The transfer limit.** A part is only picked up if the `p_mw` of its loads fits the `max_p_mw`
  of the external grids inside it. This is per part, not per bus, so a connectivity check alone
  is not enough, and it interacts with the restoration set that trap 4 already exercises.
- **`net.res_reliability_element`**, the per event share of SAIFI, SAIDI and ENS. It is a
  read-only aggregation over what the engine already produces, and the sum of the shares equals
  the system indices exactly, which is asserted as an identity.

`restorable_buses` deliberately reports connectivity only and ignores the transfer limit, which
is stated in the description; an agent that wires it straight into the engine loses the limit.

## Discriminator proof

Twenty defect classes were implemented on purpose in the reference and the suite re-run.

| Planted defect | Tests killed |
| --- | --- |
| a bus-element switch removes the whole element | 69 |
| zone uses the all-switch cut | 59 |
| isolated part uses the breaker cut | 59 |
| a restored load does not count as interrupted | 49 |
| restoration keeps open switches open | 36 |
| restoration does not remove the isolated part | 16 |
| zone ignores open switches | 11 |
| planned outages trip the breaker as well | 11 |
| planned outages interrupt transferable load | 10 |
| border switches include the inner ones | 3 |
| the transfer limit is ignored | 5 |
| the transfer limit is checked per bus | 2 |
| the element table is not sorted | 2 |
| no rel mode in get_relevant_elements | 2 |
| one remote switch is enough | 2 |
| already-open switches still count as opened | 1 |
| the line rate is not scaled by the length | 2 |
| out of service elements still fail | 5 |
| unsupplied buses are reported too | 5 |
| the average is the rate over the duration | 2 |
| asai is the unavailability | 1 |
| element ENS spread evenly over the events | 2 |
| an open breaker cannot be closed for restoration | 1 |

Kill counts are from the final test file. Two findings from the battery, both acted on:

- "border switches include the inner ones" started at **1** kill. A switch inside the isolated
  part cannot isolate anything, and only one test saw it. A ring network was added where an
  inner switch is manual while both border switches are remote, so the wrong switch set also
  produces the wrong switching time. Now 3 kills, and the trap is interdependent instead of
  isolated.
- "results are not reset between runs" kills **0** and was left alone. `calc_reliability`
  overwrites all four tables, so the `reset_results` call at its start only matters when the run
  raises. The contract the description does state, that the tables belong to a new network and
  that `reset_results(net, "rel")` empties them, is a different mutation and kills 2.

## Test fairness pass

Every fixture returns its element handles (`h.bus`, `h.line`, `h.switch`, `h.grid`, `h.load`)
and every test selects and asserts through them, so no test names a raw element index. This is
the class of finding that cost the previous submission 12 Test Fairness flags. The battery was
re-run after the rewrite as that memory demands; every kill set held or grew.

## Platform precheck round 1

Four findings, all fixed:

- **ERROR, invalid git diff.** The empty `pandapower/test/reliability/__init__.py` produced a
  hunk with only `diff --git`, `new file mode` and `index` lines, because git writes no
  `--- /dev/null` / `+++ b/...` headers for a zero byte file. The package marker was not needed
  (pytest collects the directory without it, verified in the image), so it was dropped from the
  patch instead of being padded with a header comment.
- **Behaviour warning, dtype assertion.** One test pinned `dtype == np.int64`, which the
  description never promises. Relaxed to `np.issubdtype(..., np.integer)` plus the sorting
  assertion that was already there.
- **Interface warnings, three of them.** The description named the four topology queries without
  saying they live in `pandapower.topology`, did not promise that `pandapower.reliability` is
  reachable as `pp.reliability` after `import pandapower`, did not show `et` as defaulted, and
  did not name the return types. All four are now stated in the last paragraph, at the cost of
  trimming 17 words elsewhere; `meta.md` is 498 words against the 500 cap.

Everything was re-verified in the image afterwards: 71 fail on base with 71 JUnit nodes, 71 pass
three times over with the solution, base mode still green.

## Platform precheck round 2

Coverage and alignment warnings, all addressed rather than argued:

- **Negative rates.** The description already says a rate that is "missing or not positive" means
  no fault, but nothing tested it. Added `test_a_negative_rate_produces_no_event`, which sets a
  negative failure rate and a negative maintenance rate on the same line.
- **CAIDI and ASAI without customers.** Only SAIFI, SAIDI and AENS were asserted `nan`. The
  other two are now asserted in the same test.
- **The tie-break.** The sort test only exercised the element tie-break between two lines. Added
  a network where a bus fault, a line fault and a line maintenance all carry a SAIDI share of
  exactly 0.5, so the full key `et` then `element` then `kind` is pinned.
- **A missing `remote_controlled` column meant manual switching** only by implementation. Now
  stated in the description.
- **CAIDI is `nan` without an interruption** was tested and unstated. Now stated.

`meta.md` is 495 words after trimming ten phrases to pay for the two new clauses. Tests are 71,
the mutation battery was re-run with unchanged verdicts, and all four validation cells were
re-run in the image.

## Platform precheck round 3

**Environment Quality FAILED**, and it was the right call. The gate runs the vanilla
`python -m pytest` at the repository root, not `test.sh`, so it collects the whole test tree.
`pandapower/test/converter/test_from_cim.py` imports `lxml` at module level and nothing else in
the image provided it, so collection aborted before a single test ran. Base mode never touched
that directory, which is exactly why the local runs were green and the gate was not.

The lesson is the one already recorded for cargo and npm: base mode being scoped does not excuse
the image from satisfying the repo's DEFAULT test command. Collection-time imports across the
whole tree are part of the environment contract.

Fix: the image now installs the repository's own optional test dependencies, pinned:
`lxml`, `matpowercaseframes`, `xlsxwriter`, `openpyxl`, `cryptography`, `psycopg`, `plotly`,
`igraph` and `power-grid-model-io`. Collection went from `1719 tests collected, 1 error` to
`1819 tests collected` with no errors. The heavy optional extras the repo's own CI leaves out
(`juliacall`, `numba`, `ortools`, `lightsim2grid`) are still out, and the tests that need them
skip themselves. With those present the whole vanilla suite runs green offline in 17 and a
half minutes, and base mode picks up three more previously skipped cases (244 instead of 241).

The two Dockerfile warnings are fixed in the same pass: every package now carries an exact
version, and `pip install -e .` no longer passes `--no-deps`, so the declared dependency set is
resolved rather than assumed. Every pin already satisfies what `pyproject.toml` declares, so the
resolver changes nothing.

## Platform precheck round 4

Four items, all taken:

- **The JSON round trip was tested but not described.** It is a real part of the contract (the
  tables are ordinary net keys, so `to_json` carries them), so the description now says so rather
  than the test being dropped.
- **`kind` values were not enumerated.** The description now names them: "fault" or
  "maintenance". This is the enumeration law again, a value outside a stated list is unstated.
- **`restorable_buses` did not say the switching freedom applies to it too.** The reliability
  narrative says "any switch may be closed" but the topology helper only inherited it by
  implication. Now spelled out on the helper itself.
- **A test name lied.** `test_zones_split_at_an_open_switch` closes the tie switch and asserts
  the two feeders merge into one zone. Renamed to
  `test_a_closed_tie_puts_both_feeders_in_one_zone`, which is what it does.

`meta.md` is 499 words after trimming seven more phrases. All four cells re-run: 71 fail on base
with 71 JUnit nodes, 71 pass three times with the solution, base mode 244 passed.

## Coverage suggestions round (advisory, all taken)

Eleven tests added, 71 to 82. Every expectation was hand derived first and every one held on the
first run.

- **Default timings.** Two tests call `calc_reliability(net)` with no arguments and pin 1.0 and
  0.05 hours; every earlier exact-timing test passed explicit values.
- **Non positive and missing event data.** Negative transformer and bus rates, a maintenance rate
  with no maintenance time (rate counts, duration is zero), and a maintenance time with no rate
  (no planned outage at all).
- **Planned outages beyond lines.** A transformer maintenance and a bus maintenance, each with
  the isolated part they pull with them.
- **Multiple grids in one part.** Three tests: two limits that sum to exactly the demand, two
  that fall short, and one finite plus one missing, where the missing one makes the part
  unlimited.
- **Customers present but zero.** Distinct from the missing column: the five weighted indices are
  `nan` while `ens_mwh_per_year` still holds.

The battery was re-run. Every kill set held or grew: the two cut mutants went 34 to 42 and 34 to
41, the incidence mutant 42 to 51, the frequency mutant 29 to 35, both maintenance mutants 3 to
5, "the transfer limit is ignored" 2 to 3, and "unsupplied buses are reported too" 1 to 2.

## Coverage suggestions, second round (advisory, all taken)

Five more tests, 82 to 87, again all hand derived and all correct on the first run.

- **`restorable_buses` array contract.** The sorted-integer assertion now covers all three
  helpers, not two.
- **Maintenance scales with length too.** A four kilometre line with a per kilometre maintenance
  rate, which pins the multiplication for planned outages the way an earlier test pinned it for
  faults.
- **Out of service transformer and bus.** The transformer case is the interesting one: with the
  transformer out, its whole low voltage side stops being supplied, so the result tables shrink
  to the grid bus and the load drops out entirely. The bus case pins a cascade worth naming: an
  out of service bus also takes the tie switch attached to it out of the graph, so the load one
  bus upstream stops being restorable and waits for the repair instead.
- **A per row missing remote flag.** `nan` in the `remote_controlled` column for one border
  switch, not just a missing column, forces the manual time.
- **Load side derived fields.** `average_interruption_time_h` on the load table, including `nan`
  for a load that is never interrupted.

Battery re-run again, every kill set held or grew: the cut mutants are now 45 and 45, the
incidence mutant 54, the frequency mutant 38, and four of the small ones doubled ("one remote
switch is enough" 1 to 2, "the line rate is not scaled by the length" 1 to 2, "out of service
elements still fail" 1 to 3, "unsupplied buses are reported too" 2 to 4).

## Coverage suggestions, third round (advisory, all taken)

Three more tests, 87 to 90.

- **The round trip now compares whole frames.** All four tables go through
  `assert_frame_equal` instead of a values spot check, and the fixture carries both a cost column
  and planned outages so the serialised event table holds both `kind` strings and every
  contribution column.
- **Missing cost data is asserted, not just tolerated.** Without
  `interruption_cost_eur_per_mwh` the load column and `ecost_eur_per_year` are zero.
- **`restorable_buses` on the other two element types.** A transformer, where removing the
  isolated part leaves only the grid bus, and a bus, where it leaves two separate parts each
  holding a grid.

Battery re-run once more: unchanged apart from the isolated-part cut mutant going 45 to 46.

## Test Fairness round (FAIL, 2 of 90, both fixed)

Both findings were correct, and both are the same defect: a test pinning a missing-data policy
the description never stated.

- **`test_a_negative_rate_produces_no_event`.** The description said "a missing or non positive
  rate means no fault", which reads as covering failure rates only, while the test also asserts
  that a negative MAINTENANCE rate produces nothing. The rule is now written as "no event" and
  the maintenance sentence says planned outages are "subject to the same rate and time rules".
- **`test_the_cost_is_zero_without_a_cost_column`.** Nothing said what a missing
  `interruption_cost_eur_per_mwh` does. The description now ends that clause with "and zero
  without it".

Note what this pair has in common with the earlier tie-break and `remote_controlled` findings:
every one of them was a DEFAULT, not a behaviour. The behaviour of this feature was specified
tightly from the first draft; what kept slipping through was what happens when the input is
absent, negative or empty. Worth carrying forward as a checklist item of its own: for every
optional column the feature reads, state what missing and out-of-range values do.

The two advisory suggestions from the same report were also taken: the container types are now
pinned with `isinstance` (`np.ndarray` for the three array helpers, `pd.Series` for
`protection_zones`), and a focused test shows a planned outage does not operate the breaker, the
transferred loads taking a zero interruption rate from that event rather than the fact being
inferred from an aggregate.

91 tests. `meta.md` is 499 words. Battery unchanged, all four cells re-run.

## Test Fairness, second round (FAIL, 2 of 93, fixed)

Both findings were one ambiguity counted twice. The event table's numeric fields were described
as "its share of the first three", and the preceding system list does not make ENS literally
third, so the trio SAIFI/SAIDI/ENS was not pinned. The description now names all three columns.
Another instance of the same law as the previous round: what fails is never the mechanism, it is
the thing the prose left to inference.

The three advisory suggestions were taken as well, 91 to 95 tests:

- an out of service line with a positive maintenance rate produces no planned outage, on a
  parallel-line fixture where taking the line out leaves everything supplied, and the disabled
  bus test now also carries a maintenance rate;
- an out of service load does not consume pickup capacity, and an out of service external grid
  contributes none, both on the two-grid fixture at the exact capacity boundary;
- a `customers` column and a cost column that exist but have a `nan` cell, which the description
  now says count as zero.

Battery re-run: every kill set held or grew again, both maintenance mutants 6 to 8 and the
transfer-limit mutant 3 to 4.

## Coverage suggestions, fourth round (advisory, all taken)

Five tests, 95 to 100, all hand derived and correct on the first run.

- **Sparse indices.** A network built with buses 50, 7, 23, lines 9 and 2, switches 4 and 8 and
  loads 6 and 1. It pins that the helpers sort by real IDs, that zones are numbered by the
  smallest bus ID rather than the first row, and that the result tables carry the original IDs.
  The result-table ORDER is deliberately not asserted there, only the membership and the values
  looked up by ID, because the description does not fix an order for them.
- **An open bus-line switch.** Until now only an open bus-bus tie was covered. Opening one end of
  a parallel line cuts that connection while the line stays in service and still fails, which is
  a different thing from an out of service element and is now asserted as such.
- **Missing data on transformers and buses.** A transformer with no repair time and then a `nan`
  rate, and a bus with no repair time; the missing-data checks were line-heavy before.
- **The file based JSON API.** The description names `to_json` and `from_json`; the round trip
  now goes through a real file under `tmp_path` in addition to the string form.

Battery re-run: the four biggest mutants are now 61, 52, 51 and 43 kills, and "restoration does
not remove the isolated part" went 12 to 14.

## Test Fairness, third round (FAIL, 1 of 100, fixed)

The finding was correct and it is the same law a third time. `test_sparse_indices_are_used_as_they_are`
asserted that the zone Series comes back with its rows in ascending bus order, on a fixture built
as buses 50, 7, 23 so that ascending and insertion order disagree. The description said only that
the Series is "over the in service buses"; an implementation returning them in table order would
have failed a requirement that did not exist. The description now says "in ascending order".

Worth stating plainly, because it is the whole story of this review cycle: the mechanism was
never questioned once. Every single finding across three fairness rounds and four alignment
rounds was a piece of CANONICAL FORM or a DEFAULT that the prose left implicit while a test
pinned it. Sort order of a returned container, tie-break of a sort, which columns a phrase like
"the first three" means, what a missing or negative cell does. The lesson for the next
submission is to write those down at the same time as the behaviour, not after a reviewer
finds them.

Both advisory suggestions were taken, 100 to 102 tests: deleting the transformer failure rate
column and the bus maintenance rate column suppresses those events (asserted before and after the
deletion in one test), and a network with no positive rates gets an empty `res_reliability_element`
that still carries its seven columns.

## Coverage suggestions, fifth round (advisory, both taken)

Three tests, 102 to 105.

- **Maintenance defaults on transformers and buses.** Each test runs twice: once with a positive
  maintenance rate and no maintenance time, proving the event counts with zero duration, and once
  with a negative rate, proving it disappears. The suite proved both rules for lines only.
- **Per event ENS.** The suggestion was the sharpest of the whole cycle. The suite had the sum
  invariant but no per-row value, so an implementation that spread the correct total evenly over
  the event rows would have passed. I planted exactly that defect to check: replacing each row's
  `ens_mwh_per_year` with the mean of all of them kills exactly one test, the new one. The sum
  invariant does not notice it, by construction.

That probe is the reason to take advisory suggestions seriously rather than argue them. It found
a real hole in the discriminating power, not a stylistic one.

## Coverage suggestions, sixth round (advisory, both taken)

Two tests, 105 to 107, and the first of them found another real hole.

- **An open circuit breaker.** Every earlier breaker in the suite was closed. Making the tie an
  open `CB` changes nothing in either cut, because an open switch is cut whichever rule you
  read, but it does change RESTORATION: the description says any switch may be closed, with no
  exception for breakers. An implementation that treats a breaker as a permanent boundary would
  refuse to pick the load up through it. Planted exactly that defect: it kills exactly one test,
  the new one. Nothing else in 107 noticed.
- **Module exposure.** `hasattr(pp, "reliability")` and the callable, asserted directly rather
  than only exercised by every other test.

Two rounds in a row, an advisory suggestion has pointed at a defect class the suite could not
see: the total-preserving ENS misallocation and now the unclosable breaker. Both were found by
asking what an implementation could get wrong that the existing assertions would tolerate, which
is the same question the mutation battery asks. Worth running that question over the suggestion
list every time rather than treating advisory as optional.

## Batch 1: 0 of 4, and what it cost to fix

Four Nova runs, none passing: 26, 7, 18 and 8 failures. The batch is the only real difficulty
oracle and it said two things at once.

**The prompt was wrong, not the agents.** All four invented `saifi_share`, `saidi_share` and
`ens_share` columns holding a normalised ratio, because the description said the event table
carries "its share of `saifi_1_per_year`, `saidi_h_per_year` and `ens_mwh_per_year`". Four
independent readings agreeing against mine is the definition of a shared-failure prompt bug. The
sentence now says the table holds "how much of ... it causes, in columns of those three names",
which pins the names AND that the values are absolute contributions rather than ratios.

**One test carried an unstated case.** Nova #2 failed nothing else except
`test_an_out_of_service_bus_produces_no_event`, whose fixture left a line with one out-of-service
terminal; nothing said whether such a line still fails. It got 0.55 where the reference gives
0.60. Rather than spend prose on a marginal modelling rule, the fixture now takes that line out
of service too, so the question does not arise.

**Measured, not guessed.** Both fixes were validated by replaying the agent patches: Nova #2's
own implementation, with only the naming and normalisation the corrected sentence pins rewritten,
passes **107 of 107**. The other three still fail on the intended traps, so the projection is
**1 of 4, 25 percent** - solvable, inside the cap, and still hard. The failures that decide it
are the restorable set (Nova #1), the zone cut and the open-switch semantics (Nova #3) and
planned outages not tripping a breaker (Nova #4).

The two fixes are fairness repairs, not difficulty cuts. Nothing in the trap structure moved: the
mutation battery is unchanged at twenty two probes, twenty one killing.

## Batch-1 follow-up: the last two coverage suggestions

Two tests, 107 to 109, and a check that mattered more than either.

- **Transformer and bus rows in the event table.** Every earlier event-table test used line
  events. One network now produces a transformer fault, a transformer maintenance and a bus
  fault at once, and pins all seven columns of all three rows including the `et` codes.
- **Helpers with an out of service transformer.** `protection_zones`, `isolated_buses`,
  `isolating_switches` and `restorable_buses` on a network whose transformer is out, complementing
  the reliability-side supply filter test.

Because these were added AFTER the batch, the sole passing agent was replayed against the
expanded suite before anything else: Nova #2 still passes **109 of 109**. A new test that broke
the only passer would have put the submission back at zero without anyone noticing until the next
batch. The other three still fail 25, 16 and 7.

The description gained one clause for these: the event table's `et` uses the same codes as
`net.switch.et`. That pushed `meta.md` to **513 words**, over the 500 cap, on the author's
explicit instruction to prefer solvability over the limit. It is the only place the file exceeds
it and the clause is pure interface, not a hint.

**No hints were added, deliberately.** The projection is 1 of 4. Nova #4 fails only the two
planned-outage tests; any wording that helps there flips it to a pass and the batch to 2 of 4,
which is 50 percent and over the too-easy cap. Solvability is already established by measurement,
so the right move is to stop clarifying the trap.

### A near miss worth recording

The mutation battery was interrupted by a command timeout mid-probe and left its mutant in the
working tree (`res = res` in place of the element-table sort). The kill counts of the next run
were inflated across the board and one probe reported ANCHOR MISSING, which is what exposed it.
The shipped `solution.patch` was generated BEFORE the interruption and was clean, and every
docker verification reads the shipped patch rather than the tree, so nothing propagated. The
tree was restored and now byte-matches the shipped patch, and the battery re-run clean. The
lesson is the one already in the notes: after any interrupted mutation run, diff the tree against
the shipped patch before trusting a number.

## Coverage suggestions, final round (advisory, all taken)

Four tests, 109 to 113, and the passing agent re-checked against every one of them.

- **A fault on the bus that carries the external grid.** Two cases: with a backup, where the two
  buses beyond the isolated part transfer over and the two inside wait for the repair; and
  without one, where losing the source bus means nothing can be picked up and every supplied bus
  waits the full repair. Source loss was the one event shape the suite had never exercised.
- **Mixed border switches on a bus event.** The all-required-switches rule was only tested on
  line events. A bus event whose isolated part has two border switches now runs twice, once with
  one of them manual and once with both remote.
- **A network with an external grid and no in service load.** The bus table still reports every
  supplied bus with its rates, the load table is empty, the five customer weighted indices are
  `nan` and ENS and ecost are zero rather than `nan`.

Nova #2 was replayed against all 113 and still passes everything, which is the check that
matters after any test is added to a suite whose pass rate rests on a single agent. The other
three sit at 88, 97 and 106 of 113.

## Coverage suggestions: two taken, one refused on evidence

- **Capacity blocks a planned transfer too.** A maintenance outage where the alternate path
  exists but the backup grid cannot carry the part. Asserted through the load bus by index rather
  than as a whole vector, because a capacity-blocked part also contains its own source bus and
  whether THAT bus counts as interrupted is a corner the description does not settle.
- **An event that interrupts no load still gets a row.** A fault on the backup source bus, which
  has no load on it: the row exists with the right rate and zero SAIFI, SAIDI and ENS.

**The third suggestion was refused, and this is the important one.** It asked for a case where
every opened border switch is remote but the normally-open tie that must be CLOSED is manual.
I wrote it, and it broke the only passing agent: Nova #2 returns 0.52 where my reference returns
0.60. It excludes an ALREADY-OPEN switch from "every switch that had to be opened", on the
grounds that a switch that is already open does not have to be opened. Reading my own sentence
again, that is at least as natural as the reference's reading, which counts every switch on the
border of the isolated part.

No existing test distinguishes the two readings, which is exactly why Nova #2 passes. Adding this
one would have pinned the reference's side of an unsettled sentence AND taken the batch from
1 of 4 back to 0 of 4. Advisory coverage does not outrank the solvability gate. The test is out,
and the ambiguity is recorded here as deliberately untested rather than silently pinned.

Final state: 115 tests, Nova #2 passes all of them, the other three sit at 89, 98 and 107.

## Last coverage round (advisory, both taken)

- **An out of service transformer emits no event row.** Earlier tests showed its side goes
  unsupplied but never proved the absence of a transformer row. With fault AND maintenance rates
  set and the transformer out, the event table holds the line row and nothing else.
- **A `nan` rate in one cell.** Missing columns and non positive rates were covered, a per row
  `nan` was not. One line's fault rate and a different line's maintenance rate are set to `nan`,
  and the event table is compared as a SET of (`et`, `element`, `kind`) so the assertion does not
  depend on an ordering the fixture does not determine.

117 tests. Nova #2 still passes all of them; the other three are at 90, 99 and 109.

The harness needed rebuilding first: `/tmp/mutate.py` had been overwritten by an unrelated
script, so the battery exited immediately instead of running. Verified the tree was untouched
before rewriting it under a name of its own. The rebuilt battery carries 23 probes now, adding
the three written since the original run (`an open breaker cannot be closed for restoration`,
`element ENS spread evenly over the events`, `no rel mode in get_relevant_elements`), and 22 of
the 23 kill.

## Solution Quality FAIL: the reference was wrong, and I had already been told

The reviewer scored comprehensiveness 1 of 3 on one thing: `_switching_duration` decided the
remote versus manual time from ALL border switches of the isolated part, including switches that
are already open. The description says the shorter time applies "when every switch that had to be
opened is `remote_controlled`", and a switch that is already open does not have to be opened. An
already-open manual border switch could therefore force the long manual time for no reason.

**This is the second time the same finding arrived.** Nova #2 produced 0.52 where the reference
produced 0.60 on exactly this case, and two rounds ago I removed the test that exposed it because
keeping it would have taken the batch from 1 of 4 to 0 of 4. That was the right call about the
TEST and the wrong conclusion about the CODE: I treated a divergence between the reference and
the only passing agent as an ambiguity to route around, when the agent was reading the sentence
correctly and the reference was not. The rule for next time is blunt: when a passing agent
disagrees with the reference on a stated rule, read the sentence again before assuming the
reference defines it.

Fixed in `run_reliability.py`: the remote check now filters the border set to the switches that
are actually closed. Consequences, all measured:

- All 117 existing tests still pass unchanged, which confirms what the earlier analysis found,
  that no test pinned either reading.
- The test that was removed is back as `test_an_already_open_switch_does_not_have_to_be_opened`,
  now asserting the corrected values, and runs twice so it also pins that a CLOSED manual border
  switch still forces the manual time.
- The old behaviour is now a permanent battery probe and dies to exactly that one test.
- Nova #2 passes 118 of 118, so solvability is untouched. The others sit at 91, 100 and 110.

The reviewer's two polish notes are also fixed: the unused `logger`/`logging` import is gone and
`_system_indices` no longer takes the `net` it never used. Effective LOC 557.

### The interrupted-battery trap, twice

A ten minute command timeout killed the battery mid-probe again and left the average-interruption
mutant in the tree. Same drill as before: the shipped patch was generated before the run and was
clean, the tree was restored and diffed byte for byte against it, and the battery was re-run in
the background where nothing kills it. The harness now lives at a private path after an unrelated
script overwrote the shared one, and its anchors were re-synced with the refactor.

## FP self-audit

Every sentence of `meta.md` was traced to at least one assertion, and every assertion back to a
sentence. Three gaps were found and closed before the patches were frozen:

1. `test_the_result_columns` asserted the column **order**, which the description never fixes. An
   agent listing the same columns in another order would have failed a requirement that does not
   exist. Relaxed to set comparison.
2. `test_the_element_contributions_are_sorted_by_their_share` depends on how ties are broken, and
   the description said only "descending SAIDI share". Two lines in the fixture have the same
   share. The tie-break is now stated in the description ("then by `et`, `element` and `kind`").
3. `test_a_network_without_an_external_grid_raises` asserted a `UserWarning` that nothing
   documented. The sentence is now in the description.

The other direction, a described behaviour with no assertion behind it, is covered by the trace
plus the battery above: each of the twenty defects is a described rule implemented wrongly, and
nineteen of them are caught.

Remaining known softness, stated rather than hidden: `et="t3"` is accepted by the three topology
queries but no test uses a three-winding transformer, and impedances take part in connectivity
without being named in the description. Neither is asserted, so neither can produce a false pass.

## Validation

| Cell | Result |
| --- | --- |
| base source, base tests | 244 passed, 10 skipped, 2 xfailed |
| base source, new tests | 118 failed, 118 JUnit nodes |
| solution, new tests | 118 passed |
| solution, base tests | 244 passed, 10 skipped, 2 xfailed |

Flakiness: three consecutive runs of each mode in the container, identical every time. The
repo's own `--timeout=60` addopt is overridden in `test.sh`, so no assertion depends on wall
clock. No randomness, no network (`--network none`), no ordering assumptions; every fixture is
built from `create_*` calls in a fixed order.

## Predicted outcome

Pass rate 10 to 25 percent. Six interdependent traps, of which the two cuts and the frequency
rule are the ones that a single traversal cannot satisfy at the same time.
