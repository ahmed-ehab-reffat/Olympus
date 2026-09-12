# Verification

Build the image from a pristine checkout of the pinned source:

```sh
docker build \
  -t statig-local-transitions:verification \
  -f problems/statig-local-transitions/Dockerfile \
  work/statig-local-transitions/source
```

The source checkout should not contain a local `target/` directory in the
Docker context. A clean clone or archive is preferable.

Run the four required patch-state gates with networking disabled:

```sh
problems/statig-local-transitions/verify/gates.sh
```

Run the mutation suite:

```sh
problems/statig-local-transitions/verify/mutations.sh
```

Run the metadata, patch-application, file-list, leak, and size audit:

```sh
problems/statig-local-transitions/verify/audit.sh
```

The container scripts use `statig-local-transitions:verification` by default. Override
that tag with `STATIG_VERIFY_IMAGE`. The mutation runner supports one or more
named mutations as trailing arguments; with none, it runs all thirty-three.

When Docker is unavailable, the mutation runner can use an already fetched
local source checkout and Cargo cache:

```sh
STATIG_PATCH_DIR="$PWD/problems/statig-local-transitions" \
STATIG_BASE_SOURCE="$PWD/work/statig-local-transitions/source" \
problems/statig-local-transitions/verify/mutations.sh --inside
```
