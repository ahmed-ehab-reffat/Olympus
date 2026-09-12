# Railway deployment-bundle similarity audit

Status: completed on 2026-07-26 before the scope prototype. No exact local
problem duplicate was found, but the archive evidence sharpened the decisive
thin-wrapper stop rule.

## Workspace search

The search covered `problems/`, `archive/`, and `candidates/` with repository,
subsystem, and behavior terms for deployment packaging, upload planning,
archive construction, filesystem trees, deterministic manifests, ignore/root
semantics, symlinks, containment, atomic output, rollback, and serialization.

Records read included:

- `archive/3d-tiles-atomic-output/MANIFEST.md`;
- the 3D Tiles `DESIGN.md`, `SUMMARY.md`, `ENVIRONMENT.md`, `ERRORS.md`,
  `RUNS.md`, and `LEVELS.md`;
- representative raw 3D Tiles solver records from
  `archive/3d-tiles-atomic-output/agent-runs.tar.gz`;
- the Calyx checkpoint plan, prototype, design, summary, and archive manifest;
- the RustPBX redesign and SipFlow manifests/audits;
- the pydicom FileSet replacement plan/design and measured rejection;
- the go-mp4 sample-location design/summary and overlap rejection; and
- the Olympus problem and candidate indexes.

No exact Railway or cross-repository deployment-input-plan task exists in the
local records.

## Closest records and boundary

| Record | Central behavior | Railway consequence |
|---|---|---|
| 3D Tiles atomic output | Stage final directories/JSON/3TZ elsewhere, then publish with candidate/backup swaps, rollback, and missing-parent cleanup. | Distinct from selecting and inspecting upload inputs. Any Railway redesign centered on temporary publication, destination rollback, or cleanup would overlap and is forbidden. |
| Calyx Cider checkpoints | A 190-line replay checkpoint and a 144-line transcript-replay variant satisfied public behavior without serializing private runtime state. | A legitimate reconstruction/reuse shortcut cannot be prohibited merely to force the intended architecture. |
| RustPBX SipFlow | Rejected because the pinned repository already had a mature structured event store; the proposed command was a formatter/projection over it. | Direct analogue for the Railway scope gate: exposing the existing collected archive entries may be a projection, even though no public command currently exists. |
| pydicom FileSet replace | Sound task, but rejected at 72 strict effective production lines rather than padded into unrelated behavior. | Size is independently terminal even when the contract is coherent. |
| go-mp4 sample locations | Locally substantial, later rejected because another submission implemented the same cross-repository semantic core. | No corresponding Railway duplicate was accessible locally. |

## Representative trajectory evidence

The 3D Tiles raw archive checksum recorded by its manifest is
`47702773975afd2ddb4e678b05e229cce2347e7a222267e8cbbeeb1c8bf410d0`;
member listings and the following representative solver records were inspected
directly rather than relying only on summaries.

| Category | Record | Solver architecture and lesson |
|---|---|---|
| Legitimate pass | run 3, including `trajectory.json`, patch, run log, and evaluation | Inspected `PipelineExecutor` and every output target, introduced a dedicated publisher, staged all final outputs, used candidate/backup/rollback state, cleaned new parents, and proactively exercised real targets. This is a genuine multi-boundary transaction, unlike Railway's existing in-memory archive handoff. |
| Near pass | run 2 | Implemented the same sound staged-publication architecture and passed the baseline, but returned raw `Error` rather than the repository's public `PipelineError`; scored 26/30. Public error identity, not extra filesystem fixtures, was decisive. |
| Broad failure | unavailable | The remaining inspected record failed because the environment lacked `tsx`; it contained a substantial implementation but no completed behavioral verifier. It was recorded as an external execution failure, not relabeled as a broad solver failure. |

The Calyx and RustPBX compact records were sufficient for their shortcut
mechanisms. Their lesson is negative and directly applicable: tests may require
public behavior, but may not forbid reuse of the current archive helper or
require a private `Plan` pipeline to manufacture scope.

## Submission-archive access

No private platform submission-archive connector or local mirror was available
in this session. The public/local search is complete; private cross-submission
overlap remains a residual risk rather than a passed sub-gate.

## Similarity verdict

Proceed to the cheapest-solution prototype, but only on the original
inspection/planning identity. Railway remains distinct from 3D Tiles as long as
atomic publication and rollback are excluded. The RustPBX and Calyx records
make the prototype decisive: if sorting and exposing paths from the existing
collector is enough, that implementation must be accepted and the candidate
must be rejected.

No `DESIGN.md` was created. The candidate failed the subsequent pre-design
scope gate, so the trajectory-informed design ledger and hidden-test work were
not authorized.
