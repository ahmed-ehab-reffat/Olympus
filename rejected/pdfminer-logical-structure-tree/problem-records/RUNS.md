# RUNS - pdfminer.six logical structure tree

Raw local trajectories: `none; only operator-authored reference and mutation trees exist`.

Raw platform trajectories: `none`.

| Run | Model | Level | Baseline | Feature | Production files | Agent messages | Effective LOC | Verdict | Failure family | Decisive lesson |
|---:|---|---|---|---|---:|---:|---:|---|---|---|
| - | - | L1 | - | - | - | - | - | not started | - | fresh calibration is 0/10 |

## Design reference

| Role | Run or archive member | Solver architecture / shortcut | Fair discriminator implication |
|---|---|---|---|
| Legitimate pass | unavailable for pdfminer.six | no independent solver architecture yet | do not infer solver compatibility from the reference |
| Near-pass | h5py VDS Nova 6, reviewed during design | broad behavior but coarse resource identity | keep page/Form/MCID identity direct and black-box |
| Broad failure | PcapPlusPlus filtered-copy Nova 10, reviewed during design | reused an earlier boundary and rejected a legal producer | test independent child/layout producers and context changes |

## Batch decision

No calibration batch has started. The exact-version forecast is 1-3 solves out
of 10, inside band. Follow `CALIBRATION_STRATEGY.md`: first run the local
frontier pre-filter; if the version remains unchanged, begin platform probing in
batches of two. Any artifact edit abandons all prior results and restarts at
0/10 after every gate.

## Archive

Not archived; problem is active and uncalibrated.
