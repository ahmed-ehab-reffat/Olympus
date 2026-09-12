FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

# go.mod and go.sum are both committed in this repository, so the dependency graph is
# fully pinned. Resolve it from those two files alone, before the rest of the source,
# and verify every module against the checksums in go.sum.
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0

# The runtime container is offline, so resolve modules only from the cache filled
# above and never reach for the network. Skipping VCS stamping keeps the toolchain
# from shelling out to git, which fails when the container runs as a user that does
# not own the checkout.
ENV GOFLAGS="-mod=readonly -buildvcs=false"
ENV GOPROXY=off
ENV GOSUMDB=off
ENV CGO_ENABLED=0

# docs/webui builds a browser demo for js/wasm. Its ach_js.go is limited to GOOS=js by
# the filename suffix, leaving ach_other.go, which declares package main and nothing
# else, as the whole package everywhere else. That cannot link, so `go build ./...`
# fails on this platform for that one package. Supply the missing stub. Nothing
# imports the package and it has no tests.
RUN printf 'package main\n\nfunc main() {}\n' > docs/webui/ach_other.go

RUN go build ./...

# The caches have to stay usable whatever user the container runs as.
RUN chmod -R a+rwX /opt/go/pkg/mod /opt/go/cache

CMD ["/bin/bash"]
