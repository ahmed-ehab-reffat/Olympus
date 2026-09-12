# Levels

## Level 0 — complete snapshot

Versioned typed snapshot data, canonical postcard bytes, structural
validation, and full native export.

## Level 1 — unconditional restore

No-write target preflight, capability-driven ordered restore with partial
progress, portable compatibility semantics, and WASM integration.

This was version 20. All four latest saved solvers passed it, so it is retained
as a lower calibration level rather than the selected problem.

## Level 2 — sparse staged restore

After compatibility preflight, read a complete target baseline before any
mutation. Skip equal resource stages, write only dirty stages in order, treat a
late baseline read failure as preflight, and report only fully written dirty
stages as completed.

Versions 21 through 23 selected this level. All four version-23 implementations
passed it and used whole-resource writes inside dirty stages.

## Level 3 — item-sparse resumable restore

Within keymap, encoder, combo, fork, and Morse stages, write only entries that
differ from the validated baseline. Compare macros by advertised chunks and
write only dirty chunks. A retry refreshes the baseline, so entries applied
before a partial-stage failure are not rewritten.

Versions 24 and 25 selected this level. The platform reported 3 legitimate
passes in 4 unhinted runs, and the single failure was a hidden-test false
negative rather than a real defect, so the true pass rate is at least 75% and
Level 3 is spent.

## Level 4 — geometry-adaptive grouped restore

Everything in Level 3, plus two independent additions:

- a target is compatible when no geometry dimension is smaller than the
  snapshot's, so restore must compare and address entries in the target's
  coordinates and leave every slot the snapshot does not reach untouched; and
- consecutive differing entries travel in as few requests as the target's
  advertised page size allows.

Versions 26 and 27 selected this level and it went 0/5 on `agent-runs7`, but
the batch measures nothing: the page rule contradicts the repository, whose own
`split_pages` sizes writes by payload budget and whose `max_bulk_keys` is
documented only for reads. Three runs lost seven tests each to that single
assertion, one lost twelve, and one never compiled. Level 4 is retired.

## Level 4a — geometry-adaptive item-sparse restore

Level 3 plus geometry adaptation alone. A request may cover a run of
consecutive differing entries and how many it carries is unconstrained, so long
as it never carries an entry that already matches.

Versions 28 through 31 selected this level, and `agent-runs8` measured it at 4/5 (80%). Replaying the five `agent-runs7` implementations
against it gives 4/5, and the fifth fails only on an error-mapping gap that
version 28's description now closes, so the true rate is probably near 100%.
Geometry adaptation is not a difficulty lever: every run that compiled handled
the target-coordinate remapping correctly.

The old text below describes the retired Level 4. Tests judge request shape as `(first entry,
entries)`, so a single-entry setter and a one-item bulk page are equivalent and
the endpoint family stays free. The level still does not require rollback,
transactions, post-write verification, payload-budget packing, a baseline read
order, or exact request counts for encoders and forks, which have no bulk
endpoint. A rejected preflight is judged only by the absence of setters, so an
implementation may perform any read-only work before deciding.

That fallback has now been taken: version 28 dropped the grouping requirement
and kept geometry adaptation. Level 3 and Level 2 remain below it, but the
ladder no longer has an untried rung above, so the next version needs a new
lever rather than another step down. Any level change creates a new immutable
version and restarts calibration at 0/10.

## Level 5 — planned restore

Level 4a plus one rule: every request restore will issue must be encodable
within the target's advertised frame, and the host must establish that before it
sends anything. `split_pages` and `send_frame` both reject an oversized request
locally, without a device, so the shortfall is knowable up front; a restore that
streams stage by stage instead discovers it after writing earlier stages and
leaves the device changed.

Versions 32 through 50 selected this level. `agent-runs15` scored 9/10, so the canonicalization lever has been absorbed and a new one is needed. `agent-runs13` read 3/10, and 2/10 once a false positive was closed. `agent-runs12` measured 3/10, a 30% pass rate inside the 50% cap. Version 40 also drops the bulk requirement from restore. Measured 6/10 on `agent-runs9` and 6/10 on `agent-runs10`. `agent-runs9` measured version 36 at 8/10 and version 37 at 6/10. Replaying the ten saved implementations gives
1/10, down from 4/5 on `agent-runs8` alone, and every failure is the new check.
That number is a floor: all ten predate the sentence that states the rule, so a
solver who reads it should do better, and the true rate lies between 10% and the
80% previously measured.

`agent-runs8`'s run 2 already satisfies the rule without having been told, so the
level is reachable and the Solvable gate is not at risk. If a fresh batch comes
back at 0/10, drop this rule and return to Level 4a rather than easing anything
below it.

## Level 6: fewest requests under the target's geometry and frame

Versions 51 through 55 select this level. They keep every behaviour of Level 5 and replace
the canonicalization lever, which `agent-runs15` measured at 9/10 after three
description edits made it findable by every run.

Restore must spend the fewest requests per stage. A bulk request is one
contiguous run in the target's coordinates; it may carry matching entries to
bridge differing ones; it never spans a slot the snapshot does not reach; it
never begins or ends on a matching entry; it must fit the frame. Without a bulk
endpoint, only differing entries are sent, one at a time.

The point of the level is that all of that is stated. The difficulty is in
computing the plan, not in discovering the requirement, so no clarification can
erode it. Version 52 removes version 51's foreign-postcard decoder assertion;
version 53 restores only its registered testcase name after the official
wrapper reported it missing; version 54 replaces the arbitrary WASM junk-byte
fixture with implementation-native bytes plus trailing input; version 55 makes
the offline harness independent of the evaluation UID and reports startup
failures honestly in JUnit; version 56 classifies the expected test-only
compile failure as skipped while keeping genuine startup failures errored.
None of these fairness, packaging or environment repairs alters the level. No
measured rate yet; calibration starts at 0/10.
