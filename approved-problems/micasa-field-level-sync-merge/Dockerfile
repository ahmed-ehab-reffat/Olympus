FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

ENV GOTOOLCHAIN=go1.26.5
ENV GOFLAGS=-buildvcs=false

RUN git config --system --add safe.directory '*'

COPY --chown=1000:1000 . .

# The repo's .dockerignore drops .git, so recreate a local repository at the
# base commit to keep git status and git diff usable inside the container.
RUN test -e .git/HEAD || ( \
        git init -q \
        && git add -A \
        && git -c user.name=micasa -c user.email=micasa@localhost commit -q -m "0b0f92ae583bafc6242a3ed9dc756195d4162fb0" )

RUN go mod download \
    && go build ./... \
    && go vet ./internal/data/... ./internal/sync/... ./internal/relay/... ./cmd/micasa/... \
    && chmod -R a+rwX "$(go env GOCACHE)" \
    && find /app -type d -exec chmod a+rwX {} +

CMD ["/bin/bash"]
