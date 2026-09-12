FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

WORKDIR /app
COPY . /app

ENV GOFLAGS=-buildvcs=false
ENV GOCACHE=/tmp/gocache
ENV GOMODCACHE=/tmp/gomod

RUN go mod download && go build ./... && chmod -R a+rwX /tmp/gocache /tmp/gomod /app

CMD ["/bin/bash"]
