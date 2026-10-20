FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
ENV GOFLAGS=-buildvcs=false
ENV GOCACHE=/tmp/gocache
RUN apt-get update \
    && apt-get install -y --no-install-recommends redis-server \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --chown=1000:1000 . .
RUN go mod download all \
    && mkdir -p /tmp/gocache \
    && go build ./... \
    && chmod -R a+rwX /tmp/gocache \
    && chmod -R a+rX "$(go env GOMODCACHE)" \
    && git config --system --add safe.directory /app \
    && if [ -d .git ]; then git checkout -- go.mod go.sum; fi \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
