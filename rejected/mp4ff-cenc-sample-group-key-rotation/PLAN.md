# Plan - mp4ff CENC sample-group key rotation

Status: `rejected at the upstream-ownership gate; calibration 0/10`.

1. Complete the trajectory-informed startup gate. **Done: no mp4ff trajectory
   exists; relevant media/parser compact records and representative raw
   metadata-extractor and PcapPlusPlus pass/near/broad evidence were inspected
   and recorded.**
2. Audit exact source ownership and provenance. **Done: AI-assisted PR #490
   introduced the owning KID-map APIs, and its maintainer discussion explicitly
   names `seig` overrides as the later enhancement. PRs #495 and #502 publish
   the same limitation.**
3. Run the untouched offline non-root environment gate only if ownership
   survives. **Not applicable after the terminal rejection.**
4. Build a disposable cheapest-complete implementation only after Phase A.
   **Not authorized by the rejection.**
5. Author a prompt, hidden tests, and reference artifacts only after the design
   and convergence gates pass. **Not authorized by the rejection.**
6. Run Phase B, gap, fairness, false-positive, and calibration gates only for a
   frozen submission version. **Not applicable; no submission version exists.**

Any future mp4ff candidate must use a materially different public behavior and
repeat the trajectory, ownership, and environment gates from zero.
