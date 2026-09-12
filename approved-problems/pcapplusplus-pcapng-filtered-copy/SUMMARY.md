# SUMMARY - PcapPlusPlus section-aware PCAPNG filtered copy

Status: **accepted on 2026-08-01**. L5 remains retired calibration history; the
exact L6 artifact is the accepted package.

Repository: `seladb/PcapPlusPlus`

Production language: C++

Task type: feature request

Pin: `0dbbb9c75eb232135f13fdb794318c4da3270ebc`

The original experiment confirmed the user's Railway point: a small reference
did not predict participant work. Successful solver implementations were
consistently substantive. The current reference has 254 raw and 232
non-comment, non-blank production additions across two files, above the
200-effective-LOC floor without padding.

Exact L5 calibration in the archived `agent-runs4/` batch produced seven
legitimate passes and three substantive failures, so L5 is retired at 7/10.
All ten solvers already used a const-qualified API and temporary destination
publication. Those review gaps are now covered, but they are deliberately not
used to force the split.

Trajectory inspection found the distinct discriminator. Five of the seven L5
passes validated every EPB option area before applying the filter; two parsed
options only for retained EPBs. L6 adds `DiscardedPacketOptions`, whose UDP EPB
has valid fixed fields, interface reference, lengths, and packet data but a
malformed option area. A TCP filter discards it, so the copy succeeds without
interpreting bytes that are not retained. The reference validation order was
corrected accordingly.

L6 also calls `copyFiltered()` through a const reference and adds a DSB-free
same-path replacement case. All ten L5 solutions pass those two checks. Exact
L6 replay gives a varied 2/10 projection: Nova 1, 2, 4, 8, and 9 fail only
`DiscardedPacketOptions`; Nova 3 and 5 retain their broader DSB-option failures;
Nova 10 retains its DSB/multi-section failures; Nova 6 and 7 pass all 16.

All four patch states apply and pass `git diff --check`. Test-only/base passes
69/69; test-only/new reports all 16 named failures; combined/base passes
69/69; combined/new passes 16/16; and the complete solution inventories pass
`Packet++Test` 259/259 plus `Pcap++Test` 69 passed, zero failed, 44 skipped.
Python 3.8 emits all 16 simulated named build failures.

The exact L6 false-positive audit kills all 33 active repository-grounded
mutants. The non-const-only implementation builds the production library and
fails at the const test call; the identical-path and premature EPB-option
mutants fail only their own new scenarios. Historical minor-version mutant 26
remains retired as unfair.

The Dockerfile starts with
`FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`. The platform accepted
this exact L6 package on 2026-08-01, as confirmed by the user. The L5 7/10
batch and L6 replays retain their original historical meanings; no predecessor
run is relabeled as an L6 calibration result. Exact artifact identities are
frozen in `DESIGN.md` and `FALSE_POSITIVE_AUDIT.md`, and raw runs are recoverable
from `archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`.
