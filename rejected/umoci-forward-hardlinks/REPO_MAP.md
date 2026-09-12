# Repository map

- `oci/layer/unpack.go`: owns the complete tar-layer loop and is the only
  production file changed by the complete prototype.
- `oci/layer/tar_extract.go`: owns per-entry sanitization, clobbering, whiteout
  handling, hardlink creation, metadata restoration, and `upperPaths` state.
- `oci/layer/tar_extract_test.go`: establishes existing hardlink-to-file and
  hardlink-to-symlink inode behavior.
- `oci/layer/utils.go`: supplies `CleanPath` for archive path normalization.
- `pkg/fseval` and `pkg/unpriv`: provide the existing filesystem and
  unprivileged hardlink operations; no changes are required.
- `hack/test-unit.sh`: upstream unit-test entry point; the ordinary offline
  gate used `go test ./...` to avoid the coverage-only wrapper while exercising
  every Go package.

The task never reaches the CAS, manifest, CLI, repack/generation, or runtime
configuration subsystems. That isolation is the decisive scope weakness.
