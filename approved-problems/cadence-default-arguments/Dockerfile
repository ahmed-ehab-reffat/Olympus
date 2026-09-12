FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOFLAGS=-buildvcs=false
ENV GOCACHE=/tmp/gocache

WORKDIR /app

COPY . .

RUN go install github.com/jstemmer/go-junit-report/v2@v2.1.0 \
    && cp "$(go env GOPATH)/bin/go-junit-report" /usr/local/bin/go-junit-report \
    && go mod download all \
    && mkdir -p /tmp/gocache \
    && go build ./... \
    && (go vet ./ast/... ./parser/... ./sema/... ./interpreter/... ./bbq/... ./stdlib/... ./runtime/... || true) \
    && chmod -R a+rwX /tmp/gocache \
    && chmod -R a+rwX /app \
    && chmod -R a+rX "$(go env GOMODCACHE)"

CMD ["/bin/bash"]
