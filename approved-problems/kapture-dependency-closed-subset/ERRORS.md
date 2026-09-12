# Errors and corrections

No unresolved environment, verifier, reference, or fairness blocker remains in
immutable v8.

- V7's prompt required unrelated-file preservation but did not state exact
  stale-managed cleanup. Its reference recursively deleted standard roots,
  losing nested unrelated files, while its test checked only a root sentinel
  and replacement metadata. V8 explicitly requires old managed retirement and
  any-depth unrelated preservation; the reference now removes exact owned paths.
- The first v8 mutation pass found raw-string alias mutant 21 surviving because
  no-force rejection masked its missing normalized identity check. The final
  alias call uses `force=True` and verifies an unchanged source tree; every
  exact gate restarted.
- The CLI paragraph's redundant introductory deliverable sentence was removed;
  the exact PEP 621 mapping, callable, module execution, and options remain.
- Prior corrections remain: executable/JUnit harness, pinned/editable image,
  representation-neutral empty collections, no-filter full copy, saved return,
  direct force API, isolated installed wheel, reverse image seeds, and
  transactional failure.

The compatibility forecast was 1/5 and replay observed 1/5. Fresh v8
calibration remains unmeasured at 0/10; 2–4/10 is a forecast, not a result.

