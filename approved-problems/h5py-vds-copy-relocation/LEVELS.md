# LEVELS - h5py VDS reconstruction and relocation

Target calibration band: 1-5 solves in 10. Long-horizon additionally requires
the successful median to reach at least two production files, 20
platform-reported agent messages, and 200 strict-effective production LOC.

| Level | Behavioral lever | Tests | Reference scope | Solver evidence | Calibration | Verdict |
|---|---|---:|---|---|---|---|
| L1 predecessor | Direct `Group.copy` VDS relocation | 24 | platform 91 effective LOC; 1 production file | 2/10 legitimate passes; successful-agent median 133 LOC and 1 file | historical 2/10 | nominal difficulty passed; long-horizon failed |
| L1 verifier revision | Additional copy-only completeness probes | 29 | same one-file implementation | prior replays: one 29/29, one 28/29 | abandoned 0/10 | verifier stronger; architecture unchanged |
| L2 accepted redesign | Public layout reconstruction, independent relocation, composition, and copy integration | 41 | 2 production files; 249 local effective additions; conservative platform forecast about 227 | old best replay 29/41; no cold redesigned solver | historical 0/10; platform accepted 2026-08-10 | accepted and archived |

The user's platform measurements, 91 reference LOC and 133 median successful
solver LOC, supersede the old local estimate for L1. L2 is materially different:
`VirtualLayout.from_dataset` and `VirtualLayout.relocated` are independently
observable public behaviors in `_hl/vds.py`, and `Group.copy` is a separate
consumer in `_hl/group.py`. The reference crosses the local two-file/200-LOC
prefilter without counting docs or tests.

The redesigned artifact reached acceptance without a fresh cold calibration
batch, so its 0/10 state remains a historical fact rather than an inferred pass
rate. The user-confirmed platform outcome supersedes the planned calibration;
no historical copy-only run is relabeled as redesigned evidence.
