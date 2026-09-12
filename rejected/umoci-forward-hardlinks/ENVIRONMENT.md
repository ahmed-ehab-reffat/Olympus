# ENVIRONMENT - umoci forward hardlink extraction

Status: `Phase A pass; Phase B not applicable without prompt/test/reference artifacts`.

Repository pin: `f5d1219acaf67127ebacf6306776d3ff465735ea`.

## Phase A - pristine environment

- Docker: 29.2.1, arm64.
- Free space before build: 89,934,584 KiB.
- Official base digest:
  `sha256:fed7c2f8d5014c9cd9635da6ab143e90f219b67bc35a236a48a30814f0e4b990`.
- Built with `docker build --pull --no-cache` from a clean exact checkout.
- Result image:
  `sha256:259dcbcc6d034ee45110f1f1d591071b363e3df83105a4d8c5402dfb368afd9b`.
- Offline image-copy discovery as UID/GID 10001 passed
  `go test -run '^$' ./...`.
- Offline read-only-checkout execution as UID/GID 10001 passed
  `go build ./...`, `go test -run '^$' ./...`, and the complete ordinary
  `go test ./...` package lane.
- `go`, `go-junit-report`, module metadata, vendored metadata, and warmed caches
  were readable. `GOPROXY=off` and `GOSUMDB=off` were active.

Verdict: **pass** for the pristine candidate Dockerfile.

## Phase B - exact evaluator composition

Not run. `meta.md`, `test.patch`, and `solution.patch` do not exist. If the
convergence trial permits authoring, any artifact creation or edit requires a
fresh Phase A build and exact Phase B before downstream behavioral audits.
