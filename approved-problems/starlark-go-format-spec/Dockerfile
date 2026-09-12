FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOFLAGS=-buildvcs=false
ENV GOPATH=/root/go
ENV PATH=/root/go/bin:/usr/local/bin:${PATH}

WORKDIR /app
COPY . .

RUN go mod download \
    && GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0 \
    && go build ./...

CMD ["/bin/bash"]
