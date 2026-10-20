FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

ENV GOTOOLCHAIN=go1.27.2
ENV GOFLAGS=-buildvcs=false

RUN git config --system --add safe.directory '*'

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-15 libnss-wrapper \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=1000:1000 . .

# The repo's .dockerignore drops docs/, so regenerate the CLI reference that
# cmd/micasa keeps in sync with its commands.
RUN go mod download \
    && mkdir -p docs/content/docs/reference \
    && go generate ./cmd/micasa/ \
    && chmod a+rw docs/content/docs/reference/cli.md

# The repo's .dockerignore drops .git, so recreate a local repository at the
# base commit to keep git status and git diff usable inside the container.
RUN test -e .git/HEAD || ( \
        git init -q \
        && git add -A \
        && git -c user.name=micasa -c user.email=micasa@localhost commit -q -m "ca69a88f998dec25c1e285121e428a4f7621dc68" )

RUN go build ./... \
    && CGO_ENABLED=0 go build -o /dev/null ./cmd/micasa \
    && go vet ./internal/data/... ./internal/sync/... ./internal/relay/... ./cmd/micasa/... \
    && chmod -R a+rwX "$(go env GOCACHE)" \
    && find /app -type d -exec chmod a+rwX {} +

CMD ["/bin/bash"]
