FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
ENV GOFLAGS=-buildvcs=false
ENV GOCACHE=/gocache
WORKDIR /app
COPY . .
RUN go mod download all && go build ./... && go vet ./mp4/ > /dev/null 2>&1 || true
RUN chmod -R a+rwX /gocache /app
CMD ["/bin/bash"]
