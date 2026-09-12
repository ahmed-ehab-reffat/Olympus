FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY . .

ENV GOFLAGS=-buildvcs=false
ENV CGO_ENABLED=0

RUN go mod download && \
    go build ./... && \
    GOBIN=/usr/local/bin go install golang.org/x/tools/cmd/goyacc@v0.48.0

RUN chmod -R a+rwX /app "$(go env GOMODCACHE)" "$(go env GOCACHE)" && \
    chmod a+rx /usr/local/bin/goyacc

CMD ["/bin/bash"]
