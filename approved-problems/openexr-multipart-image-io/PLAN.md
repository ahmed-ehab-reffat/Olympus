# Plan - OpenEXR multipart Image I/O

Status: `immutable revision v9.1 exact gates pass; calibration 0/10`.

1. Pin OpenEXR at `c101ab742a9e93c8c9c6f1781055e938cc160305`. **Complete.**
2. Read the design/calibration protocols and inspect every `agent-runs6` artifact and raw trajectory. **Complete.**
3. Record the trajectory-derived v9 discriminator ledger before changing submission artifacts. **Complete.**
4. Add hybrid selective rewrite across filename and caller-owned streams. **Complete.**
5. Repair unsupported-sibling loading and complete save-validation symmetry. **Complete.**
6. Audit all rewrite validation, exact-name, UTF-8, crop, unknown-type, and isolation branches across overloads. **Complete.**
7. Restart and pass the exact offline arbitrary-UID environment gate after each artifact revision. **Complete.**
8. Complete the 60-mutant false-positive audit, exact gap analysis, and exact fairness analysis. **Complete.**
9. Run the 127-case pre-existing suite and controlled harness-failure probes. **Complete.**
10. Remove the unsupported invalid-save stream atomicity assertion and repeat every exact-version gate. **Complete.**
11. Freeze v9.1 at 0/10 and begin a fresh calibration batch without changing artifacts. **Pending.**

Revision v9.1 retains the v9 architecture while correcting one fairness predicate. No fresh solver result exists. The correct handoff is “harder and uncalibrated,” not a claimed barely-solvable score.
