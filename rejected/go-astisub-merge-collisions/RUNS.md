# RUNS - go-astisub merge collisions

Raw local trajectories: none. Raw platform trajectories: none.

The pre-T4 version had four unhinted Nova runs and all four passed. Their median
message count was 14.5 and median effective production size was 169 LOC, below
the Olympus long-horizon floors. After T4 changed `test.patch`, that version was
abandoned and the revised calibration count reset to 0/10.

All four saved solution patches were replayed against the revised seven-test
suite and passed unchanged. This replay is trajectory evidence, not calibration
runs for the new immutable version. The result confirms the region discriminator
closes a correctness hole but does not harden the task materially.

Status: closed and archived on 2026-08-01. Raw evidence is in
`archive/go-astisub-merge-collisions/agent-runs.tar.gz`. No further runs should
be spent on this task shape.
