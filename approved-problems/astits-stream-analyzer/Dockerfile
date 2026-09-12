FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
ENV GOPATH=/go
ENV GOCACHE=/go/cache
ENV GOFLAGS=-buildvcs=false
ENV PATH="/go/bin:${PATH}"
WORKDIR /app
COPY . .
RUN go mod download all \
    && go install github.com/jstemmer/go-junit-report/v2@v2.1.0 \
    && go build ./... \
    && chmod -R a+rwX /go /app
CMD ["/bin/bash"]
