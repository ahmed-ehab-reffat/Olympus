# Authoring errors and resolutions

| Finding | Classification | Resolution |
|---|---|---|
| Maven base wrapper attempted root-home initialization for an arbitrary UID | environment blocker | clear the image entrypoint and invoke Bash/Maven directly |
| root-owned `target` from the image build could not be copied up by UID 10001 | environment blocker | remove only generated `/app/target` after dependency population and rebuild cold |
| repository helper mounted a tree read-only while Maven needed generated output | evaluator-path blocker | use fresh writable composition trees with the same implementation-then-test order |
| prior Docker manifest returned a content-store input/output error | environment blocker | quarantine the entire batch, restart Docker Desktop, rebuild with pull/no-cache, and restart every gate from zero |
| a draft required foreign-origin rejection before transfer execution | fairness defect | require only rejection and unchanged zone; leave validation order free |
| a draft required exactly one `run()` call for current mode | fairness defect | require execution at least once and the promised no-op state |
| initial deletion concurrency hook paused on an accessor not reached by deletion | deterministic-probe defect | pause delete-side on `getName()` and add-side on `getRRsetType()`, then rerun the reference and alternate architectures |
| the transfer-rollback mutation was first applied to the AXFR constructor's `run()` call | mutation-isolation error | discard that result, move the mutation to `applyIXFR`, and rerun predecessor and final suites |
| omitting all delete validation incidentally bypassed the concurrency latch | mutation-isolation error | refine the mutant to validate names but omit only class, proving the intended new direction in isolation |

Every environment incident was stopped before behavioral interpretation. No
quarantined run is counted as a failed solution or as mutation evidence.
