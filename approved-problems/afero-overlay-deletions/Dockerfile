FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
WORKDIR /app
COPY . .
ENV GOFLAGS=-buildvcs=false
ENV GOCACHE=/app/.gocache
ENV GOPATH=/app/.gopath
RUN go install github.com/jstemmer/go-junit-report/v2@v2.1.0 \
    && cp "$(go env GOPATH)/bin/go-junit-report" /usr/local/bin/go-junit-report \
    && go mod download && go build ./... && chmod -R a+rwX /app
CMD ["/bin/bash"]
