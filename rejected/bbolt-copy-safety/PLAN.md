# Plan - bbolt snapshot-copy safety

Status: `rejected after the pre-authoring fairness/convergence probe;
calibration 0/10`.

1. Complete the trajectory-informed design gate. **Done: no bbolt trajectory
   exists; the closest copy/recovery records and representative raw h5py runs
   were reviewed and recorded.**
2. Build the untouched exact pin and run its supported ordinary lane offline as
   a non-root UID. **Done: Phase A passed after quarantining two invalid
   discovery compositions.**
3. Reproduce source-path aliases and compare the cheapest complete repairs.
   **Done: pristine truncates direct, hard-link, and symbolic-link sources;
   two fixes pass at 13 additions and 15 additions/1 deletion in `tx.go`.**
4. Audit the proposed `WriteTo` short-write and `Compact` extensions for public
   provenance and distinct implementation depth. **Done: the writer violates
   its interface contract, and compaction repeats or leaves the supported
   operation boundary.**
5. Freeze a public prompt and submission artifacts only if the convergence
   gate survives. **Not authorized by the rejection.**
6. Run Phase B, gap, fairness, false-positive, and calibration gates only after
   submission artifacts exist. **Not applicable.**

Any future bbolt candidate must begin with a materially different public
behavior and repeat the design and environment gates; it cannot inherit this
Phase A verdict.
