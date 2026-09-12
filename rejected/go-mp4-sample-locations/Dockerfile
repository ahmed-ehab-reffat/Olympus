FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY . .

RUN go mod download all
RUN GOBIN=/usr/local/bin go install gotest.tools/gotestsum@v1.13.0

ENV GOFLAGS="-mod=readonly"
ENV CGO_ENABLED=0

RUN go build ./...

CMD ["/bin/bash"]
