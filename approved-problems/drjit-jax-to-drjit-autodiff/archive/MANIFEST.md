# Dr.Jit JAX-to-Dr.Jit autodiff archive

Outcome: accepted and archived on 2026-08-20 after user-confirmed platform success.

Repository: `mitsuba-renderer/drjit` at `c0798bb752172e8ced661443cf308dc3a19d678c`.

The canonical submission package remains in `problems/drjit-jax-to-drjit-autodiff/`. Its immutable artifacts are `meta.md`, `test.patch`, `solution.patch`, and `Dockerfile`. The final reference passed 22/22 focused tests and 84 base tests with 63 skips; pristine failed 22/22 focused tests. All 18 local false-positive mutants were rejected. Retained compatible solvers passed 13, 14, 13, 15, and 14 focused cases while completing the base lane. Fresh calibration remained 0/10 for this exact version; platform acceptance is the user-confirmed outcome.

Cold evidence retained here:

- `candidate-records/DESIGN.md`: the preliminary candidate design record, copied byte-for-byte before the active candidate directory was retired.
- `raw-runs/agent-runs1.zip`: the raw solver bundle. `unzip -t` passed, and all 40 substantive members matched the extracted active copy byte-for-byte before that duplicate extraction was removed.
- `cleanup-inventory-pre.json`: helper-generated pre-cleanup inventory for canonical, candidate, representative temporary, and Docker resources.
- `removed-temporary-paths.txt`: the frozen list of 201 task-scoped temporary roots removed during cleanup.
- `docker-resources.tsv`: the exact 17 image IDs removed; no task-scoped containers existed.
- `cleanup-inventory.tsv`: compact classification and disposition record.
- `cleanup-inventory-post.json`: post-cleanup verification inventory.
- `SHA256SUMS`: hashes for the immutable submission artifacts and retained cold evidence.

Reconstruction requires the pinned upstream checkout, the four canonical submission artifacts, and an offline-capable evaluator environment matching the build contract in `Dockerfile`. Raw trajectories can be recovered from `raw-runs/agent-runs1.zip`; temporary build trees, mutation checkouts, probe logs, and Docker images were reproducible caches and were intentionally removed.
