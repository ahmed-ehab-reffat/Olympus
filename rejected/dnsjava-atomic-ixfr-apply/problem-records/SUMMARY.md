# Summary - dnsjava atomic IXFR application

Repository: `dnsjava/dnsjava` at
`06a0599933114f36efe59667cd80ee0246a1a882`.

Language: Java. Task type: enhancement. Candidate rating: 8/10.

State: `rejected as previously implemented; archived; calibration closed at 0/10`.

The task adds public atomic IXFR application to `Zone`: execute the transfer,
validate its full RFC 1982 serial/SOA chain and record ownership, replay each
delete before add against staged state, validate the final zone, and publish one
complete generation without changing caller-owned deltas. Current responses are
no-ops, AXFR fallback is rejected, and every failure rolls back.

The reference changes one production file with 119 additions. Two independent
staged-list/map implementations also pass the exact evaluator, while a
22-addition per-record shortcut exposes both partially removed and partially
added RRsets. The final hidden suite has seventeen named cases. Three new cases
each kill a single demonstrated predecessor survivor; the fourth covers the
independent add-side publication direction.

The untouched offline arbitrary-UID suite passes 1,739 tests. Exact evaluator
composition yields pristine base 121/121 and feature 17 named failures;
reference and both legitimate alternates pass 121/121 plus 17/17. The reference
combined suite passes 1,756 tests with 29 skips. Environment, gap, fairness, and
false-positive gates pass for the frozen artifacts.

No local frontier or platform solver run was counted. The user subsequently
reported that the task was rejected because the feature had already been
implemented before. This outcome supersedes the local novelty verdict: the
exact task is terminal and must not be calibrated, resubmitted, or cosmetically
rescoped.
