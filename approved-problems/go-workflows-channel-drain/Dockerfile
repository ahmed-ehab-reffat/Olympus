FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOPATH="/root/go"
ENV PATH="/root/go/bin:${PATH}"

WORKDIR /app

COPY . .

RUN go mod download && \
    GOBIN=/root/go/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0 && \
    go build ./...

CMD ["/bin/bash"]
