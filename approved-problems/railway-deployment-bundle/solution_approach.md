# Solution approach

The implementation first extracts Railway's existing walking and archive-name
selection into a shared collector. Ordinary uploads keep using that collector,
so planning does not need to recreate ignore rules, root selection, or followed
link behavior in a parallel implementation. Offline command setup mirrors the
ordinary local-root decision: linked configuration supplies the root only when
no project is explicit and no project-token or environment-variable targeting
is active. Explicit projects, project tokens, and environment targeting keep
the current directory as the source root, matching ordinary `up` without
performing an offline remote lookup.

A new deployment-plan controller owns the strict JSON schema and validation.
Planning collects and sorts entries by normalized archive path, records type,
size, Unix permission bits, and SHA-256 for regular files, and serializes the
validated structure with stable pretty JSON. The requested plan pathname is
normalized and excluded during collection, which makes an in-tree plan safe to
rewrite without selecting its previous output. Strict validation also requires
raw plans read from disk to retain increasing, unique entry paths and requires
every Unix file and directory record to contain its permission mode, so a
mode-less record is malformed during reading or serialization rather than only
during later reconciliation. Each regular file is opened once; relevant
pathname metadata is captured immediately before opening, then descriptor
metadata is checked after opening and again after reading and digesting the
bytes. The followed pathname is inspected again after reading and, on Unix,
its device and inode must still identify the opened object; the portable
fallback rechecks its size and modification metadata. The byte count is also
checked against the stable length. Planning refuses a source that is not
regular when opened and detects replacement, size, Unix mode, or
modification-metadata changes while its contents are read, instead of
persisting metadata and a digest from different moments.

Applying a plan validates the schema and invocation options, recollects the
current selection, and compares the complete ordered entry set before building
an archive. Each regular file is opened once into a snapshot containing its
metadata, digest, and bytes. The digest and metadata are checked against the
plan, then the same in-memory bytes are appended to the tar stream. Directories
are also rechecked before append. This removes the verify-then-reopen gap while
preserving ordinary tar metadata and link-following behavior.

The `up` command handles both plan modes before constructing an authorized
client. Writing returns immediately. Applying constructs and verifies the
planned archive first, then performs the deferred token refresh and resumes the
existing project, service, upload, and deployment path. Top-level command
classification also exempts both plan modes from the eager refresh that normal
authenticated commands receive, staged/background update work, agent
advisories, and telemetry. The zero-request guarantee therefore belongs to the
command rather than to caller-provided opt-out variables. The verified archive
is retained across project and service resolution and supplied directly as the
upload request body; the command does not rebuild it after local verification.
Clap conflicts make either mode incompatible with the other and with `--new`.
