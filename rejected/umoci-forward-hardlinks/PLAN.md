# PLAN - umoci forward hardlink extraction

1. Complete the local-history, raw-trajectory, source-history, and upstream
   ownership audit. **Done.**
2. Prove the untouched pin builds and runs its full ordinary Go test suite
   offline as an arbitrary non-root UID in the official base. **Done.**
3. Implement the cheapest complete same-layer forward-hardlink behavior in the
   isolated audit checkout, including chains, replacement order, symlink inode
   identity, invalid dependencies, and confinement. **Done.**
4. Measure production files and strict effective LOC. Reject without hidden
   tests if the result converges on one small state queue or direct public
   recipe; do not add unrelated OCI behavior or malformed fixtures. **Done:
   rejected at one production file, 54 raw / 48 strict additions.**
5. Only if the convergence gate passes, author `meta.md`, additive hidden tests,
   `test.patch`, and `solution.patch`, then rerun exact Phase A and Phase B.
   **Not authorized by the rejected gate.**
6. After exact environment success, perform gap, fairness, and false-positive
   audits before any calibration recommendation. **Not applicable.**
