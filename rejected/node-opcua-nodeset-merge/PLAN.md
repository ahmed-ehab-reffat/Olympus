# Plan — node-opcua deterministic multi-model NodeSet export

Status: `review revision 4 locally verified; calibration 0/10`.

1. Freeze `node-opcua/node-opcua` at
   `e233d906138995583f42359831d1908e3cb005e7` and the public helper contract.
2. Record the trajectory-informed design ledger before hidden-test authoring.
3. Pass the untouched and exact-composition environment gates offline as an
   arbitrary non-root UID.
4. Implement and verify the reference through the repository-native exporter,
   dependency, translation, and loader seams.
5. Complete mutation-driven gap, fairness, and false-positive audits.
6. Freeze hashes and registry state.
7. Run the local frontier pre-filter, then—only if the immutable version remains
   viable—start a fresh ten-run solver calibration batch from `0/10`.

Steps 1–6 are complete for immutable revision 4, including thirteen-test
identity parity and a zero-based fifteen-mutant rerun. Step 7 has not begun.
Any submission-artifact change returns the plan to Step 3 and calibration to
`0/10`.
