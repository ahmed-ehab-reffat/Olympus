FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY . .

ENV GOFLAGS="-mod=mod -buildvcs=false"
ENV GOCACHE=/tmp/gocache

RUN go install github.com/jstemmer/go-junit-report/v2@v2.1.0 \
    && cp "$(go env GOPATH)/bin/go-junit-report" /usr/local/bin/go-junit-report \
    && go mod download all \
    && go build ./... \
    && mkdir -p /tmp/gocache \
    && chmod -R a+rwX /tmp/gocache \
    && chmod -R a+rwX /app \
    && chmod -R a+rX "$(go env GOMODCACHE)"

CMD ["/bin/bash"]
