# Archived — platform environment failure

Archived on 2026-08-11. This problem is retired and must not be calibrated or
submitted in its present environment. Calibration remains `0/10`.

Repository: `node-opcua/node-opcua` at
`e233d906138995583f42359831d1908e3cb005e7`.

Challenge: `kh778fbqvn0qd5wqbwtxkfjxnh8c66rs`.

## Terminal failure

Shipd failed three distinct evaluator image records before any solver or test
process started:

- `im-Wemk161Bsqc6RBpdKrljLW`
- `im-fBWE9ZVQywsN5dG9uE5RQA`
- `im-7NYIPWZIo3cDR19lk9noMD`

The latter two IDs were allocated after Dockerfile identity changes. The final
retry used revision 8, whose clean AMD64 image was 78,439,308 bytes smaller than
revision 7. It nevertheless failed with the same generic environment result.
The only displayed build detail was “Docker build log is empty, image was
cached.” No Docker instruction, exit status, evaluator log, solver patch, JUnit,
or testcase result was exposed.

This establishes that stale Docker identity, image-size reduction, test count,
and participant behavior did not resolve the platform failure. The surviving
evidence supports only a Shipd image-builder/build-context failure; it does not
identify a failing Docker instruction. These attempts are quarantined
environment no-starts, not failed solutions.

## Local countercheck

The accepted TypeScript base image and pinned upstream commit built cleanly for
`linux/amd64` with `--pull --no-cache`. The final image started offline as
arbitrary UID/GID 10001. Exact evaluator composition passed the two selected
legacy regressions and all fifteen reference feature cases; pristine produced
the same fifteen named behavioral failures, with no hook, startup, skip,
permission, dependency, or patch-application node.

Local viability does not override the repeated platform no-start. The problem
is archived as environment-blocked.

## Preserved payloads

The `payloads/` directory preserves the final dirty working checkout, the named
`/private/tmp/node-opcua-*` authoring evidence, and a loadable archive of the
final AMD64 revision-8 Docker image. `DOCKER_RESOURCES.md` records every removed
task-specific image. Generated manifests enumerate archived and removed paths.
`PAYLOADS.sha256` binds all preserved payloads and manifests.
