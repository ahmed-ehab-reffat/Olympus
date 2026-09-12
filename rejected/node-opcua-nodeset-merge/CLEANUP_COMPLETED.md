# Cleanup completed

Cleanup completed on 2026-08-11 after archive validation.

## Removed source locations

- `problems/node-opcua-nodeset-merge`
- `Work/node-opcua-nodeset-merge-escalation`
- `candidates/node-opcua-nodeset-merge`
- all 28 exact `/private/tmp/node-opcua-*` roots enumerated by
  `private-tmp-targets.txt`

The problem record was moved to `archive/node-opcua-nodeset-merge`. The working
checkout and candidate are preserved in
`payloads/workspace-and-candidate.tar.gz`; temp evidence is preserved in
`payloads/private-tmp-node-opcua.tar.gz`.

## Removed Docker resources

- five exact task-specific image tags and image records listed in
  `DOCKER_RESOURCES.md`;
- fourteen exact reclaimable, unshared BuildKit records: six node-opcua build
  steps plus their eight task-specific `COPY`/`WORKDIR` ancestors.

There were no task-specific containers or volumes. Post-cleanup inventory finds
no image, container, volume, or BuildKit description matching `node-opcua` or
`nodeset-merge`. The final AMD64 revision-8 image remains loadable from
`payloads/olympus-node-opcua-amd64-r8.tar.gz`.

The active `rmk-hid-transport-handoff` environment gate discovered during
inventory was unrelated and was not stopped or altered. Shared base images,
unrelated Docker resources, and global caches were not pruned.

## Validation

- `PAYLOADS.sha256`: all six entries pass.
- `ARTIFACTS.sha256`: all nine entries pass.
- all three gzip archives pass integrity checks.
- all archived payloads have allocated blocks and no macOS `dataless` flag.
- free host space increased from approximately 6.3 GiB to 18 GiB after archive
  creation and cleanup.

`ARCHIVE_FILE_MANIFEST.txt` enumerates the durable archive files.
`payloads/workspace-paths.txt` enumerates the 21,543 paths removed from the
working checkout and candidate after preservation.
`payloads/private-tmp-paths.txt` enumerates the 74,769 archived temp paths; they
belong to exactly the 28 roots listed in `private-tmp-targets.txt`.
