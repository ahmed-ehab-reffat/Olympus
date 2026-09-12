Title: Add transactional pipeline output publication

Add a transactional output-publication feature.

Treat staging, target finalization, and publication as one transaction. If any of them fails, an output that existed before the call must remain entry-for-entry and byte-for-byte unchanged. If the logical output did not exist, the call must not leave it behind. Preserve the requested JSON basename when the output is given as a JSON path. Every failed call in this workflow must reject with `PipelineError`.

With overwrite enabled, updating a directory must retain unrelated files already in that directory, while replacing every colliding entry with the staged entry, including file-to-directory and directory-to-file replacements. Packages are replaced by the complete new package. With overwrite disabled, directory entry collisions and existing package files must fail without changing the original destination.

An input and output that resolve to the same logical storage must work with overwrite enabled, including a JSON path that aliases its input directory and directory or package storage.

A failed call must remove any destination parent directories it created without removing the nearest pre-existing ancestor.

Configure the temporary-storage base through `PipelineExecutor.setTempBaseDirectory(directory: string | undefined)`, where a string selects a custom base and `undefined` restores the default system temporary location. Retain a configured temporary-storage base directory but remove all pipeline scratch data after both successful and failed runs, including when the base had to be created or is located inside an existing directory output. An existing configured base that is not a directory must make the call fail before publication. The default system temporary location must receive the same scratch cleanup.

Cleanup or rollback trouble must not replace or augment the primary pipeline error. Keep the original `PipelineError` message as the primary diagnostic; cleanup diagnostics may be logged separately.
