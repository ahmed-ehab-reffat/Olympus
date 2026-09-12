FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOFLAGS=-buildvcs=false \
    GOTOOLCHAIN=local \
    GOPATH=/go \
    GOCACHE=/gocache

WORKDIR /app
COPY . .

# The test patch is applied after this image is built and the tests then run
# with no network, so every module the repository needs is downloaded here.
# The packages and their test binaries are then compiled to warm the build
# cache; compiling a test binary does not run it. The caches and the work tree
# are made group and world writable because the evaluation runs as a non-root
# user.
RUN go mod download all \
    && go build ./... \
    && for pkg in $(go list ./...); do go test -c -o /dev/null "$pkg"; done \
    && chmod -R a+rwX /app /go /gocache

CMD ["/bin/bash"]
