# Solution approach — transactional pipeline publication

**Archived reference approach for the abandoned candidate.**

## Separate execution from publication

`PipelineExecutor` creates a unique execution workspace for every non-empty
pipeline, including a single-stage pipeline. Every stage and the final target
write there. The caller's output is therefore untouched while content is being
processed and while `.3tz`, `.3dtiles`, filesystem, or custom-JSON targets run
their finalizers.

The configured temporary base is validated before execution. If absent it is
created and retained; if it is not a directory, execution fails before any
destination change. Only the per-call child is invocation-owned and removed.

## Prepare a complete candidate

After the finalizer succeeds, publication creates a second private workspace on
the destination filesystem. Package output is copied into a complete candidate
package. Directory-style output is assembled by copying the existing directory
and overlaying the staged result.

The overlay replaces colliding entries recursively, including file-to-directory
and directory-to-file changes. With overwrite disabled, the same traversal is a
read-only collision preflight. Scratch storage nested inside an existing output
is excluded from the candidate, so execution details cannot become published.
Custom JSON output uses its requested basename inside the candidate directory.

This preparation also makes same-storage input/output safe: the source remains
available until all stage reads, target finalization, and candidate construction
are complete.

## Commit and rollback

Only a completed candidate reaches the commit step. Missing destination parents
are created at that point and recorded. An existing destination is renamed into
the private publication workspace, the candidate is renamed into place, and the
backup is removed only after the new destination is visible.

If publication fails, the new path is withdrawn and the backup is restored.
Invocation-created empty parents are removed in reverse order. The nearest
pre-existing ancestor and a custom temporary base are never treated as owned.

## Cleanup and error identity

Execution and publication workspaces share a `finally` cleanup path on success
and failure. Cleanup and rollback exceptions are logged when another error is
already primary. They do not replace or append to that error's message.
Filesystem, setup, finalization, overwrite, and publication failures are exposed
as `PipelineError`; an existing `PipelineError` is returned unchanged.
