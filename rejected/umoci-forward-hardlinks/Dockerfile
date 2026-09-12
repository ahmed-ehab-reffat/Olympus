FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0

ENV GOFLAGS="-mod=readonly -buildvcs=false"
ENV GOPROXY=off
ENV GOSUMDB=off

RUN go build ./...
RUN go test -run '^$' ./...
RUN chmod -R a+rwX /opt/go/pkg/mod /opt/go/cache

CMD ["/bin/bash"]
