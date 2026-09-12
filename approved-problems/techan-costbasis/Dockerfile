FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app

COPY . .

ENV GOFLAGS="-mod=mod -buildvcs=false"

RUN go mod download \
    && go build ./... \
    && chmod -R a+rX "$(go env GOPATH)/pkg/mod" \
    && chmod -R a+rwX /app \
    && mkdir -p /tmp/gocache && chmod 777 /tmp/gocache

ENV GOCACHE=/tmp/gocache

CMD ["/bin/bash"]
