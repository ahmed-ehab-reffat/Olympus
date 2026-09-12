FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY . .

# The repository ships a .dockerignore which keeps test files, builtin.jq and
# the CLI test data out of any image built from it; restore them from the
# checkout so the suite is present.
RUN git checkout HEAD -- . && test -f cli/cli_test.go

ENV GOFLAGS=-buildvcs=false

RUN go mod download && go build ./...

RUN chmod -R a+rwX /app "$(go env GOMODCACHE)" "$(go env GOCACHE)"

CMD ["/bin/bash"]
